-- ============================================================================
--  DuoBozor — схемаи пурраи PostgreSQL 16
--  Маркетплейси гурӯҳхаридӣ бо escrow-пардохт
--  Версия 1.0 · 23.10.2026
--  Иҷро:  psql -d duobozor -f database.sql
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- email/phone бе ҳарфҳои калон
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- ҷустуҷӯи матнӣ

CREATE SCHEMA IF NOT EXISTS app;             -- доменҳои асосӣ
CREATE SCHEMA IF NOT EXISTS money;           -- молиявӣ (дастрасӣ маҳдуд)
CREATE SCHEMA IF NOT EXISTS ops;             -- амалиёт/аудит
SET search_path = app, money, ops, public;

-- ============================================================================
--  0. ENUM-ҳо
-- ============================================================================
CREATE TYPE user_status      AS ENUM ('pending','active','suspended','deleted');
CREATE TYPE role_code        AS ENUM ('super_admin','admin','manager','support','seller','buyer','courier');
CREATE TYPE kyc_status       AS ENUM ('none','pending','approved','rejected');
CREATE TYPE seller_status    AS ENUM ('draft','pending_kyc','active','suspended','closed');
CREATE TYPE product_status   AS ENUM ('draft','pending_review','active','rejected','archived');
CREATE TYPE order_status     AS ENUM ('CREATED','AWAITING_PAYMENT','PAID_HELD','CONFIRMED','PACKED',
                                      'SHIPPED','DELIVERED','COMPLETED','CANCELLED','DISPUTED','REFUNDED');
CREATE TYPE payment_method   AS ENUM ('psp_card','alipay','wallet','cash_on_delivery');
CREATE TYPE payment_status   AS ENUM ('pending','authorized','captured','failed','refunded','partially_refunded');
CREATE TYPE escrow_state     AS ENUM ('held','partially_released','released','refunded','frozen');
CREATE TYPE ledger_kind      AS ENUM ('escrow_in','payment_fee','commission','manager_bonus',
                                      'seller_payable','refund','payout','cashback','adjustment');
CREATE TYPE payout_status    AS ENUM ('requested','approved','processing','sent','rejected','failed');
CREATE TYPE dispute_status   AS ENUM ('open','under_review','awaiting_buyer','awaiting_seller','resolved_buyer','resolved_seller','resolved_split','closed');
CREATE TYPE groupbuy_status  AS ENUM ('open','success','failed','expired');
CREATE TYPE shipment_status  AS ENUM ('pending','ready','picked_up','in_transit','out_for_delivery','delivered','failed','returned');

-- ============================================================================
--  1. IDENTITY — корбарон, нақшҳо, сессияҳо
-- ============================================================================
CREATE TABLE users (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    phone           citext UNIQUE NOT NULL,
    email           citext UNIQUE,
    password_hash   text,                        -- null барои харидорони OTP-only
    full_name       text,
    avatar_url      text,
    locale          text NOT NULL DEFAULT 'tj' CHECK (locale IN ('tj','ru','en')),
    status          user_status NOT NULL DEFAULT 'pending',
    phone_verified_at timestamptz,
    totp_secret_enc bytea,                       -- 2FA (шифршуда)
    totp_enabled    boolean NOT NULL DEFAULT false,
    last_login_at   timestamptz,
    failed_logins   smallint NOT NULL DEFAULT 0,
    locked_until    timestamptz,
    referral_code   text UNIQUE,
    referred_by     uuid REFERENCES users(id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_referral ON users(referred_by);

CREATE TABLE roles (
    code        role_code PRIMARY KEY,
    title_tj    text NOT NULL,
    title_ru    text NOT NULL
);
INSERT INTO roles VALUES
 ('super_admin','Соҳиб / Супер-админ','Владелец / Супер-админ'),
 ('admin','Админ','Администратор'),
 ('manager','Менеджер','Менеджер'),
 ('support','Дастгирӣ','Поддержка'),
 ('seller','Фурӯшанда','Продавец'),
 ('buyer','Харидор','Покупатель'),
 ('courier','Курер','Курьер');

CREATE TABLE user_roles (
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        role_code NOT NULL REFERENCES roles(code),
    granted_by  uuid REFERENCES users(id),
    granted_at  timestamptz NOT NULL DEFAULT now(),
    expires_at  timestamptz,
    PRIMARY KEY (user_id, role)
);

-- scope: менеджер танҳо категория/минтақаи худро мебинад
CREATE TABLE role_scopes (
    id          bigserial PRIMARY KEY,
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scope_type  text NOT NULL CHECK (scope_type IN ('category','region','shop')),
    scope_id    uuid NOT NULL
);
CREATE INDEX idx_role_scopes_user ON role_scopes(user_id, scope_type);

CREATE TABLE sessions (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id     text,
    device_info   jsonb,
    ip            inet,
    user_agent    text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    last_seen_at  timestamptz NOT NULL DEFAULT now(),
    revoked_at    timestamptz
);
CREATE INDEX idx_sessions_user ON sessions(user_id) WHERE revoked_at IS NULL;

CREATE TABLE refresh_tokens (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id  uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    token_hash  text NOT NULL UNIQUE,            -- ҳеҷ гоҳ токени холис
    expires_at  timestamptz NOT NULL,
    rotated_from uuid REFERENCES refresh_tokens(id),
    used_at     timestamptz,
    revoked_at  timestamptz
);
CREATE INDEX idx_rt_session ON refresh_tokens(session_id);

CREATE TABLE otp_codes (
    id          bigserial PRIMARY KEY,
    phone       citext NOT NULL,
    code_hash   text NOT NULL,
    purpose     text NOT NULL DEFAULT 'login',
    attempts    smallint NOT NULL DEFAULT 0,
    expires_at  timestamptz NOT NULL,
    consumed_at timestamptz,
    ip          inet,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_otp_phone ON otp_codes(phone, created_at DESC);

CREATE TABLE kyc_documents (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doc_type    text NOT NULL CHECK (doc_type IN ('passport','id_card','license','tax_cert')),
    file_key    text NOT NULL,                   -- S3 key, на URL-и оммавӣ
    status      kyc_status NOT NULL DEFAULT 'pending',
    reviewed_by uuid REFERENCES users(id),
    reviewed_at timestamptz,
    reject_reason text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
--  1b. IDENTITY PROVIDERS — телефон / Telegram / Google / Apple / Email
--      Қоида: аккаунт = user_id. Телефон танҳо ЯК КАЛИД аст.
--      Рақам иваз шавад → фармоишҳо боқӣ мемонанд.
-- ============================================================================
CREATE TYPE auth_provider AS ENUM ('phone','telegram','google','apple','email','facebook');

-- Ҳар як роҳи воридшавӣ = як сатр. Як корбар метавонад 3–4 дошта бошад.
CREATE TABLE auth_identities (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider       auth_provider NOT NULL,
    provider_uid   text NOT NULL,             -- phone: E.164 | telegram: chat_id | google: sub
    display_hint   text,                      -- «+992 92 *** 45 67», «@farzona_tj»
    email          citext,
    meta           jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_primary     boolean NOT NULL DEFAULT false,
    verified_at    timestamptz,
    last_used_at   timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_uid)           -- калид дар ҷаҳон ягона аст
);
CREATE INDEX idx_ident_user ON auth_identities(user_id);
CREATE UNIQUE INDEX idx_ident_primary ON auth_identities(user_id) WHERE is_primary;

-- Рақамҳои кӯҳна: барои он ки калидҳои гумшуда ба аккаунти дуруст баргарданд
CREATE TABLE phone_history (
    id          bigserial PRIMARY KEY,
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_e164  citext NOT NULL,
    valid_from  timestamptz NOT NULL DEFAULT now(),
    valid_to    timestamptz,
    released_at timestamptz,                  -- баъд аз ин рақам ба дигар корбар рафт
    reason      text CHECK (reason IN ('changed','released','blocked'))
);
CREATE INDEX idx_phone_hist ON phone_history(phone_e164);

-- Ҳар кӯшиши воридшавӣ (барои детектори фиреб ва дастгирӣ)
CREATE TABLE auth_events (
    id          bigserial PRIMARY KEY,
    user_id     uuid REFERENCES users(id),
    provider    auth_provider,
    event       text NOT NULL,                -- login_ok, otp_fail, link_ok, phone_changed…
    result      text NOT NULL CHECK (result IN ('ok','fail','blocked')),
    phone_e164  citext,
    ip          inet,
    device_id   text,
    user_agent  text,
    geo         text,
    meta        jsonb,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_auth_events_user ON auth_events(user_id, created_at DESC);
CREATE INDEX idx_auth_events_phone ON auth_events(phone_e164, created_at DESC);

-- OAuth/Telegram state-и якдафъаина (replay-gard)
CREATE TABLE oauth_states (
    state      text PRIMARY KEY,
    provider   auth_provider NOT NULL,
    user_id    uuid REFERENCES users(id),
    redirect   text,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL DEFAULT (now() + interval '10 minutes'),
    used_at    timestamptz
);

-- ── Нормализатсияи рақам: ҳама форматҳо → E.164 ───────────────────────────
--   '992921234567' | '+992 92 123-45-67' | '0921234567' | '8 (92) 123 45 67'
--                       ↓
--              '+992921234567'   ← ҲАМЕША як сатр
CREATE OR REPLACE FUNCTION normalize_phone(p text, p_default_cc text DEFAULT '992')
RETURNS citext LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE d text;
BEGIN
    IF p IS NULL THEN RETURN NULL; END IF;

    d := regexp_replace(p, '[^0-9]', '', 'g');          -- танҳо рақамҳо

    IF d LIKE '00%' THEN d := substr(d, 3); END IF;      -- 00992… → 992…

    -- Тартиб муҳим аст: аввал форматҳои маҳаллӣ, баъд санҷиши дарозӣ
    IF length(d) = 9  THEN d := p_default_cc || d; END IF;                       -- 921234567
    IF length(d) = 10 AND left(d,1) = '0' THEN d := p_default_cc || substr(d, 2); END IF;  -- 0921234567
    IF length(d) IN (10,11) AND left(d,1) = '8' THEN d := p_default_cc || substr(d, 2); END IF; -- 8 (92)…

    -- Ҳимоя: E.164 = 11..15 рақам. «123» ё «+999» — нодуруст → NULL
    IF length(d) < 11 OR length(d) > 15 THEN RETURN NULL; END IF;

    RETURN ('+' || d)::citext;
END $$;

-- users.phone ҳамеша каноникӣ сабт мешавад
CREATE OR REPLACE FUNCTION trg_normalize_user_phone() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.phone IS NOT NULL THEN NEW.phone := normalize_phone(NEW.phone); END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_users_phone_norm BEFORE INSERT OR UPDATE OF phone ON users
  FOR EACH ROW EXECUTE FUNCTION trg_normalize_user_phone();

-- auth_identities.provider_uid барои телефон низ каноникӣ
CREATE OR REPLACE FUNCTION trg_normalize_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.provider = 'phone' THEN
        NEW.provider_uid := normalize_phone(NEW.provider_uid)::text;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_identity_norm BEFORE INSERT OR UPDATE ON auth_identities
  FOR EACH ROW EXECUTE FUNCTION trg_normalize_identity();

-- Ҳангоми иваз кардани рақам: кӯҳна ба таърих, нав ҳамчун identity
CREATE OR REPLACE FUNCTION log_phone_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    -- INSERT: рақами аввалин низ ба таърих
    IF TG_OP = 'INSERT' THEN
        INSERT INTO phone_history(user_id, phone_e164) VALUES (NEW.id, NEW.phone);
        RETURN NEW;
    END IF;

    IF NEW.phone IS DISTINCT FROM OLD.phone THEN
        UPDATE phone_history SET valid_to = now(), reason = 'changed'
         WHERE user_id = NEW.id AND valid_to IS NULL;
        INSERT INTO phone_history(user_id, phone_e164) VALUES (NEW.id, NEW.phone);
        INSERT INTO auth_events(user_id, provider, event, result, phone_e164)
        VALUES (NEW.id, 'phone', 'phone_changed', 'ok', NEW.phone);
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_phone_change AFTER INSERT OR UPDATE OF phone ON users
  FOR EACH ROW EXECUTE FUNCTION log_phone_change();

-- ============================================================================
--  2. SELLER — фурӯшандагон ва дӯконҳо
-- ============================================================================
CREATE TABLE sellers (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id      uuid NOT NULL REFERENCES users(id),
    legal_name         text NOT NULL,
    inn                text,                     -- рақами муаррифии андоз
    status             seller_status NOT NULL DEFAULT 'draft',
    rating             numeric(3,2) NOT NULL DEFAULT 5.00 CHECK (rating BETWEEN 0 AND 5),
    commission_rate    numeric(5,4),             -- агар фарқ кунад (0.0800 = 8%)
    payout_hold_days   smallint NOT NULL DEFAULT 1,
    approved_by        uuid REFERENCES users(id),
    approved_at        timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_sellers_status ON sellers(status);

CREATE TABLE shops (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id     uuid NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
    name          text NOT NULL,
    slug          citext UNIQUE NOT NULL,
    description   text,
    logo_url      text,
    cover_url     text,
    region        text,
    is_official   boolean NOT NULL DEFAULT false,
    status        text NOT NULL DEFAULT 'active' CHECK (status IN ('active','hidden','suspended')),
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE shop_members (
    shop_id  uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    user_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role     text NOT NULL DEFAULT 'staff' CHECK (role IN ('owner','manager','staff')),
    PRIMARY KEY (shop_id, user_id)
);

CREATE TABLE seller_payout_accounts (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id    uuid NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
    method       text NOT NULL CHECK (method IN ('bank_card','bank_account','psp_wallet')),
    holder_name  text NOT NULL,
    account_enc  bytea NOT NULL,                 -- шифршуда (AES-256-GCM)
    account_mask text NOT NULL,                  -- **** 1234 барои намоиш
    is_default   boolean NOT NULL DEFAULT false,
    verified_at  timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
--  3. CATALOG
-- ============================================================================
CREATE TABLE categories (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   uuid REFERENCES categories(id),
    name_tj     text NOT NULL,
    name_ru     text NOT NULL,
    slug        citext UNIQUE NOT NULL,
    icon        text,
    commission_rate numeric(5,4) NOT NULL DEFAULT 0.0800,   -- 8%
    sort_order  int NOT NULL DEFAULT 0,
    is_active   boolean NOT NULL DEFAULT true
);

CREATE TABLE products (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id        uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    category_id    uuid NOT NULL REFERENCES categories(id),
    title_tj       text NOT NULL,
    title_ru       text NOT NULL,
    description_tj text,
    description_ru text,
    base_price     numeric(12,2) NOT NULL CHECK (base_price >= 0),
    group_price    numeric(12,2) CHECK (group_price >= 0 AND group_price <= base_price),
    group_min_size smallint NOT NULL DEFAULT 2 CHECK (group_min_size BETWEEN 2 AND 50),
    currency       char(3) NOT NULL DEFAULT 'TJS',
    status         product_status NOT NULL DEFAULT 'draft',
    moderation_note text,
    rating_avg     numeric(3,2) NOT NULL DEFAULT 0,
    rating_count   int NOT NULL DEFAULT 0,
    sold_count     int NOT NULL DEFAULT 0,
    return_rate    numeric(5,4) NOT NULL DEFAULT 0,
    is_flash_deal  boolean NOT NULL DEFAULT false,
    seo_tags       text[],
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_group_price CHECK (group_price IS NULL OR group_price < base_price)
);
CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_cat_status ON products(category_id, status) WHERE status = 'active';
CREATE INDEX idx_products_search ON products USING gin ((title_tj || ' ' || title_ru) gin_trgm_ops);

CREATE TABLE product_variants (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id   uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku          text NOT NULL,
    attrs        jsonb NOT NULL DEFAULT '{}'::jsonb,   -- {"size":"42","color":"black"}
    price        numeric(12,2) NOT NULL,
    group_price  numeric(12,2),
    stock        int NOT NULL DEFAULT 0 CHECK (stock >= 0),
    reserved     int NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    weight_g     int,
    created_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (product_id, sku),
    CONSTRAINT chk_stock_reserved CHECK (reserved <= stock)
);
CREATE INDEX idx_variants_product ON product_variants(product_id);

CREATE TABLE product_media (
    id         bigserial PRIMARY KEY,
    product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id uuid REFERENCES product_variants(id) ON DELETE CASCADE,
    url        text NOT NULL,
    sort_order int NOT NULL DEFAULT 0,
    is_video   boolean NOT NULL DEFAULT false
);

CREATE TABLE inventory_moves (
    id         bigserial PRIMARY KEY,
    variant_id uuid NOT NULL REFERENCES product_variants(id),
    delta      int NOT NULL,
    reason     text NOT NULL CHECK (reason IN ('restock','order','cancel','return','adjust','damage')),
    ref_type   text,
    ref_id     uuid,
    actor_id   uuid REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
--  4. COMMERCE — сабад, фармоиш, расонидан
-- ============================================================================
CREATE TABLE addresses (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label      text,
    region     text NOT NULL,
    city       text NOT NULL,
    address    text NOT NULL,
    lat        numeric(9,6),
    lng        numeric(9,6),
    recipient  text NOT NULL,
    phone      text NOT NULL,
    is_default boolean NOT NULL DEFAULT false
);

CREATE TABLE pickup_points (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name      text NOT NULL,
    region    text NOT NULL,
    city      text NOT NULL,
    address   text NOT NULL,
    lat       numeric(9,6),
    lng       numeric(9,6),
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE carts (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);
CREATE TABLE cart_items (
    id         bigserial PRIMARY KEY,
    cart_id    uuid NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    variant_id uuid NOT NULL REFERENCES product_variants(id),
    qty        int NOT NULL CHECK (qty > 0),
    group_buy_id uuid,                            -- агар аз гурӯҳ омада бошад
    added_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (cart_id, variant_id)
);

CREATE TABLE orders (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_no          text UNIQUE NOT NULL,        -- DB-2026-000123
    buyer_id          uuid NOT NULL REFERENCES users(id),
    shop_id           uuid NOT NULL REFERENCES shops(id),
    seller_id         uuid NOT NULL REFERENCES sellers(id),
    status            order_status NOT NULL DEFAULT 'CREATED',
    subtotal          numeric(12,2) NOT NULL,
    discount_total    numeric(12,2) NOT NULL DEFAULT 0,
    shipping_fee      numeric(12,2) NOT NULL DEFAULT 0,
    total             numeric(12,2) NOT NULL,
    currency          char(3) NOT NULL DEFAULT 'TJS',
    group_buy_id      uuid,
    coupon_id         uuid,
    payment_method    payment_method,
    shipping_address  jsonb,                       -- snapshot
    pickup_point_id   uuid REFERENCES pickup_points(id),
    buyer_note        text,
    confirmed_at      timestamptz,                 -- «Гирифтам»
    auto_release_at   timestamptz,                 -- confirmed_at + 7 рӯз
    completed_at      timestamptz,
    cancelled_at      timestamptz,
    cancel_reason     text,
    managed_by        uuid REFERENCES users(id),   -- менеджери масъул (барои бонус)
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_buyer ON orders(buyer_id, created_at DESC);
CREATE INDEX idx_orders_seller ON orders(seller_id, status);
CREATE INDEX idx_orders_status ON orders(status, created_at);
CREATE INDEX idx_orders_auto_release ON orders(auto_release_at) WHERE status IN ('DELIVERED');

CREATE TABLE order_items (
    id           bigserial PRIMARY KEY,
    order_id     uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id   uuid NOT NULL REFERENCES products(id),
    variant_id   uuid NOT NULL REFERENCES product_variants(id),
    shop_id      uuid NOT NULL REFERENCES shops(id),
    title_snap   text NOT NULL,
    attrs_snap   jsonb,
    image_snap   text,
    unit_price   numeric(12,2) NOT NULL,
    qty          int NOT NULL CHECK (qty > 0),
    line_total   numeric(12,2) NOT NULL,
    commission_rate numeric(5,4) NOT NULL DEFAULT 0.0800,
    is_group_buy boolean NOT NULL DEFAULT false
);
CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE order_status_history (
    id         bigserial PRIMARY KEY,
    order_id   uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    from_status order_status,
    to_status   order_status NOT NULL,
    actor_id    uuid REFERENCES users(id),
    note        text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE shipments (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    courier_id      uuid REFERENCES users(id),
    status          shipment_status NOT NULL DEFAULT 'pending',
    tracking_no     text,
    carrier         text,
    pickup_point_id uuid REFERENCES pickup_points(id),
    shipped_at      timestamptz,
    delivered_at    timestamptz,
    delivery_photo  text,
    delivery_otp_hash text,                        -- тасдиқи қабул бо OTP
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_shipments_order ON shipments(order_id);

CREATE TABLE return_requests (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   uuid NOT NULL REFERENCES orders(id),
    buyer_id   uuid NOT NULL REFERENCES users(id),
    reason     text NOT NULL,
    photos     text[],
    status     text NOT NULL DEFAULT 'requested'
               CHECK (status IN ('requested','approved','rejected','shipped_back','refunded')),
    decided_by uuid REFERENCES users(id),
    decided_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
--  5. GROUP BUY — ҳастаи Pinduoduo
-- ============================================================================
CREATE TABLE group_buys (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id     uuid NOT NULL REFERENCES products(id),
    variant_id     uuid REFERENCES product_variants(id),
    initiator_id   uuid NOT NULL REFERENCES users(id),
    required_members smallint NOT NULL CHECK (required_members BETWEEN 2 AND 50),
    joined_count   smallint NOT NULL DEFAULT 1,
    group_price    numeric(12,2) NOT NULL,
    status         groupbuy_status NOT NULL DEFAULT 'open',
    expires_at     timestamptz NOT NULL,           -- одатан +24 соат
    completed_at   timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_gb_open ON group_buys(status, expires_at) WHERE status = 'open';
CREATE INDEX idx_gb_product ON group_buys(product_id);

CREATE TABLE group_members (
    id           bigserial PRIMARY KEY,
    group_buy_id uuid NOT NULL REFERENCES group_buys(id) ON DELETE CASCADE,
    user_id      uuid NOT NULL REFERENCES users(id),
    order_id     uuid REFERENCES orders(id),
    joined_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (group_buy_id, user_id)
);

CREATE TABLE group_invites (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_buy_id uuid NOT NULL REFERENCES group_buys(id) ON DELETE CASCADE,
    inviter_id   uuid NOT NULL REFERENCES users(id),
    invitee_phone citext,
    channel      text CHECK (channel IN ('whatsapp','telegram','sms','link','qr')),
    opened_at    timestamptz,
    converted_at timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
--  6. MONEY — ҳамёнҳо, ledger, пардохт, ESCROW, payout
--     (ба схемаи алоҳидаи money — дастрасӣ бо GRANT маҳдуд мешавад)
-- ============================================================================
SET search_path = money, app, public;
CREATE TABLE wallets (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid REFERENCES users(id),
    seller_id   uuid REFERENCES sellers(id),
    kind        text NOT NULL CHECK (kind IN ('buyer','seller','platform','cashback','escrow')),
    currency    char(3) NOT NULL DEFAULT 'TJS',
    balance     numeric(14,2) NOT NULL DEFAULT 0,     -- кэш барои хондан; ҳақиқат = ledger
    pending     numeric(14,2) NOT NULL DEFAULT 0,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CHECK (user_id IS NOT NULL OR seller_id IS NOT NULL)
);
CREATE UNIQUE INDEX idx_wallet_user_kind ON wallets(user_id, kind) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX idx_wallet_seller_kind ON wallets(seller_id, kind) WHERE seller_id IS NOT NULL;

-- Ҳисобҳои double-entry
CREATE TABLE ledger_accounts (
    code       text PRIMARY KEY,                  -- 'escrow:order:<uuid>', 'seller:<id>:payable'
    kind       ledger_kind NOT NULL,
    owner_ref  text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Ҳар як ҳаракати маблағ = 2 сабт (дебет + кредит), ҳамеша қуфл мешавад
CREATE TABLE ledger_entries (
    id           bigserial PRIMARY KEY,
    txn_id       uuid NOT NULL,                    -- як амалиёт = як txn_id
    debit_acct   text NOT NULL REFERENCES ledger_accounts(code),
    credit_acct  text NOT NULL REFERENCES ledger_accounts(code),
    amount       numeric(14,2) NOT NULL CHECK (amount > 0),
    currency     char(3) NOT NULL DEFAULT 'TJS',
    kind         ledger_kind NOT NULL,
    order_id     uuid REFERENCES orders(id),
    actor_id     uuid REFERENCES users(id),
    memo         text,
    idempotency_key text UNIQUE,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_ledger_order ON ledger_entries(order_id);
CREATE INDEX idx_ledger_txn ON ledger_entries(txn_id);
CREATE INDEX idx_ledger_created ON ledger_entries(created_at);

CREATE TABLE payments (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id       uuid NOT NULL REFERENCES orders(id),
    buyer_id       uuid NOT NULL REFERENCES users(id),
    method         payment_method NOT NULL,
    status         payment_status NOT NULL DEFAULT 'pending',
    amount         numeric(12,2) NOT NULL,
    currency       char(3) NOT NULL DEFAULT 'TJS',
    psp            text,
    psp_intent_id  text,
    psp_ref        text,
    idempotency_key text UNIQUE NOT NULL,
    raw_webhook    jsonb,
    paid_at        timestamptz,
    failed_reason  text,
    created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_order ON payments(order_id);

CREATE TABLE escrow_holds (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        uuid NOT NULL REFERENCES orders(id),
    seller_id       uuid NOT NULL REFERENCES sellers(id),
    amount          numeric(12,2) NOT NULL,
    currency        char(3) NOT NULL DEFAULT 'TJS',
    state           escrow_state NOT NULL DEFAULT 'held',
    held_at         timestamptz NOT NULL DEFAULT now(),
    release_due_at  timestamptz,
    released_at     timestamptz,
    released_by     uuid REFERENCES users(id),
    second_approver uuid REFERENCES users(id),     -- 4-eye барои >2000 TJS
    release_reason  text,
    UNIQUE (order_id)
);
CREATE INDEX idx_escrow_state ON escrow_holds(state, release_due_at);

CREATE TABLE escrow_events (
    id          bigserial PRIMARY KEY,
    hold_id     uuid NOT NULL REFERENCES escrow_holds(id) ON DELETE CASCADE,
    event       text NOT NULL,
    actor_id    uuid REFERENCES users(id),
    reason_code text,
    amount      numeric(12,2),
    ip          inet,
    meta        jsonb,
    prev_hash   text,
    hash        text NOT NULL,                     -- hash-chain (immutable)
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_escrow_events_hold ON escrow_events(hold_id);

CREATE TABLE refunds (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    uuid NOT NULL REFERENCES orders(id),
    escrow_id   uuid REFERENCES escrow_holds(id),
    amount      numeric(12,2) NOT NULL CHECK (amount > 0),
    reason      text NOT NULL,
    is_partial  boolean NOT NULL DEFAULT false,
    status      text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','processed','failed')),
    approved_by uuid REFERENCES users(id),
    psp_ref     text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE payouts (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id    uuid NOT NULL REFERENCES sellers(id),
    account_id   uuid NOT NULL REFERENCES seller_payout_accounts(id),
    amount       numeric(12,2) NOT NULL CHECK (amount >= 100),
    fee          numeric(12,2) NOT NULL DEFAULT 0,
    status       payout_status NOT NULL DEFAULT 'requested',
    requested_by uuid NOT NULL REFERENCES users(id),
    approved_by  uuid REFERENCES users(id),
    approved_at  timestamptz,
    sent_at      timestamptz,
    bank_ref     text,
    reject_reason text,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_payouts_seller ON payouts(seller_id, created_at DESC);
CREATE INDEX idx_payouts_status ON payouts(status) WHERE status IN ('requested','approved','processing');

CREATE TABLE commission_rules (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scope        text NOT NULL CHECK (scope IN ('global','category','seller','product')),
    ref_id       uuid,
    rate         numeric(5,4) NOT NULL,
    manager_bonus_rate numeric(5,4) NOT NULL DEFAULT 0.1500,  -- 15% аз комиссия
    payment_fee_rate   numeric(5,4) NOT NULL DEFAULT 0.0150,  -- 1.5%
    valid_from   date NOT NULL DEFAULT current_date,
    valid_to     date,
    created_by   uuid REFERENCES users(id),
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE manager_bonuses (
    id          bigserial PRIMARY KEY,
    manager_id  uuid NOT NULL REFERENCES users(id),
    order_id    uuid NOT NULL REFERENCES orders(id),
    base_commission numeric(12,2) NOT NULL,
    rate        numeric(5,4) NOT NULL,
    amount      numeric(12,2) NOT NULL,
    paid_out_id uuid REFERENCES payouts(id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (order_id, manager_id)
);

-- Баргардонидан ба app (вагарна GROWTH/TRUST ба money мераванд)
SET search_path = app, money, ops, public;

-- ============================================================================
--  7. GROWTH
-- ============================================================================
CREATE TABLE coupons (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code         citext UNIQUE NOT NULL,
    kind         text NOT NULL CHECK (kind IN ('fixed','percent','free_shipping')),
    value        numeric(12,2) NOT NULL,
    min_order    numeric(12,2) NOT NULL DEFAULT 0,
    max_uses     int,
    used_count   int NOT NULL DEFAULT 0,
    per_user_limit int NOT NULL DEFAULT 1,
    category_id  uuid REFERENCES categories(id),
    starts_at    timestamptz NOT NULL DEFAULT now(),
    ends_at      timestamptz,
    is_active    boolean NOT NULL DEFAULT true
);

CREATE TABLE coupon_redemptions (
    id        bigserial PRIMARY KEY,
    coupon_id uuid NOT NULL REFERENCES coupons(id),
    user_id   uuid NOT NULL REFERENCES users(id),
    order_id  uuid NOT NULL REFERENCES orders(id),
    amount    numeric(12,2) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (coupon_id, order_id)
);

CREATE TABLE promotions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title_tj   text NOT NULL,
    title_ru   text NOT NULL,
    kind       text NOT NULL CHECK (kind IN ('flash_sale','banner','free_shipping','subsidy')),
    banner_url text,
    starts_at  timestamptz NOT NULL,
    ends_at    timestamptz NOT NULL,
    config     jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active  boolean NOT NULL DEFAULT true
);

CREATE TABLE flash_deal_items (
    id            bigserial PRIMARY KEY,
    promotion_id  uuid NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    variant_id    uuid NOT NULL REFERENCES product_variants(id),
    deal_price    numeric(12,2) NOT NULL,
    qty_limit     int NOT NULL,
    qty_sold      int NOT NULL DEFAULT 0
);

CREATE TABLE referrals (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id  uuid NOT NULL REFERENCES users(id),
    invitee_id  uuid NOT NULL REFERENCES users(id),
    status      text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','qualified','rewarded','expired')),
    reward_amount numeric(12,2),
    qualified_at timestamptz,                      -- пас аз хариди аввалини invitee
    created_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (invitee_id)
);

CREATE TABLE points_ledger (
    id        bigserial PRIMARY KEY,
    user_id   uuid NOT NULL REFERENCES users(id),
    delta     int NOT NULL,
    reason    text NOT NULL,
    ref_id    uuid,
    expires_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE gamification_state (                 -- «Боғи ман»
    user_id      uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    tree_level   smallint NOT NULL DEFAULT 1,
    water_drops  int NOT NULL DEFAULT 0,
    last_watered timestamptz,
    harvest_count int NOT NULL DEFAULT 0
);

-- ============================================================================
--  8. TRUST — баҳо, баҳс, паём
-- ============================================================================
CREATE TABLE reviews (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    uuid NOT NULL REFERENCES orders(id),
    product_id  uuid NOT NULL REFERENCES products(id),
    buyer_id    uuid NOT NULL REFERENCES users(id),
    seller_id   uuid NOT NULL REFERENCES sellers(id),
    rating      smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     text,
    photos      text[],
    seller_reply text,
    is_hidden   boolean NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (order_id, product_id, buyer_id)
);

CREATE TABLE disputes (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    uuid NOT NULL REFERENCES orders(id),
    buyer_id    uuid NOT NULL REFERENCES users(id),
    seller_id   uuid NOT NULL REFERENCES sellers(id),
    reason_code text NOT NULL CHECK (reason_code IN
                ('not_delivered','damaged','wrong_item','not_as_described','refund_not_received','other')),
    description text NOT NULL,
    photos      text[],
    status      dispute_status NOT NULL DEFAULT 'open',
    assigned_to uuid REFERENCES users(id),
    resolution  text,
    refund_amount numeric(12,2),
    sla_due_at  timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
    resolved_at timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_disputes_status ON disputes(status, sla_due_at);

CREATE TABLE dispute_messages (
    id         bigserial PRIMARY KEY,
    dispute_id uuid NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
    sender_id  uuid NOT NULL REFERENCES users(id),
    body       text NOT NULL,
    attachments text[],
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    id         bigserial PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel    text NOT NULL CHECK (channel IN ('push','sms','email','inapp')),
    title      text NOT NULL,
    body       text,
    data       jsonb,
    read_at    timestamptz,
    sent_at    timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_notif_user ON notifications(user_id, created_at DESC);

-- ============================================================================
--  9. OPS — аудит, танзимот
-- ============================================================================
SET search_path = ops, app, public;
CREATE TABLE audit_log (
    id         bigserial PRIMARY KEY,
    actor_id   uuid REFERENCES users(id),
    actor_role role_code,
    action     text NOT NULL,                      -- 'escrow.release', 'seller.approve'
    entity     text NOT NULL,
    entity_id  uuid,
    before     jsonb,
    after      jsonb,
    ip         inet,
    user_agent text,
    prev_hash  text,
    hash       text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_actor ON audit_log(actor_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_log(entity, entity_id);

CREATE TABLE settings (
    key        text PRIMARY KEY,
    value      jsonb NOT NULL,
    updated_by uuid REFERENCES users(id),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE feature_flags (
    key        text PRIMARY KEY,
    enabled    boolean NOT NULL DEFAULT false,
    rollout_pct smallint NOT NULL DEFAULT 0 CHECK (rollout_pct BETWEEN 0 AND 100)
);

CREATE TABLE outbox_events (                       -- transactional outbox
    id         bigserial PRIMARY KEY,
    topic      text NOT NULL,
    payload    jsonb NOT NULL,
    processed_at timestamptz,
    attempts   smallint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_outbox_pending ON outbox_events(created_at) WHERE processed_at IS NULL;

-- Баргардонидани search_path барои қисмҳои боқимонда
SET search_path = app, money, ops, public;

-- ============================================================================
--  10. ТРИГГЕРҳО
-- ============================================================================
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE TRIGGER trg_products_touch BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_orders_touch BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_users_touch BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Таърихи ҳолатҳои фармоиш худкор сабт мешавад
CREATE OR REPLACE FUNCTION log_order_status() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO order_status_history(order_id, from_status, to_status)
    VALUES (NEW.id, OLD.status, NEW.status);
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_order_status AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION log_order_status();

-- auto_release_at худкор ҳисоб мешавад ҳангоми тасдиқи қабул
CREATE OR REPLACE FUNCTION set_auto_release() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.confirmed_at IS NOT NULL AND OLD.confirmed_at IS NULL THEN
    NEW.auto_release_at := NEW.confirmed_at + interval '7 days';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_order_auto_release BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION set_auto_release();

-- Ҳисоби рейтинги маҳсулот
CREATE OR REPLACE FUNCTION refresh_product_rating() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE products p SET
    rating_avg = COALESCE((SELECT round(avg(rating)::numeric,2) FROM reviews WHERE product_id = p.id AND NOT is_hidden), 0),
    rating_count = (SELECT count(*) FROM reviews WHERE product_id = p.id AND NOT is_hidden)
  WHERE p.id = COALESCE(NEW.product_id, OLD.product_id);
  RETURN NULL;
END $$;
CREATE TRIGGER trg_review_rating AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION refresh_product_rating();

-- Захира ҳангоми фармоиш кам мешавад (reserved, на stock — то бекор нашавад)
CREATE OR REPLACE FUNCTION reserve_stock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE product_variants SET reserved = reserved + NEW.qty WHERE id = NEW.variant_id;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_reserve_stock AFTER INSERT ON order_items
  FOR EACH ROW EXECUTE FUNCTION reserve_stock();

-- ============================================================================
--  11. VIEW-ҳои ҳисоботӣ
-- ============================================================================
CREATE VIEW v_escrow_summary AS
SELECT date_trunc('day', held_at) AS day,
       count(*) FILTER (WHERE state = 'held')            AS holds_open,
       sum(amount) FILTER (WHERE state = 'held')         AS held_amount,
       sum(amount) FILTER (WHERE state = 'released')     AS released_amount,
       sum(amount) FILTER (WHERE state = 'refunded')     AS refunded_amount
FROM escrow_holds GROUP BY 1 ORDER BY 1 DESC;

CREATE VIEW v_seller_balance AS
SELECT s.id AS seller_id,
       COALESCE(sum(e.amount) FILTER (WHERE e.state = 'held'), 0)      AS pending_amount,
       COALESCE(sum(e.amount) FILTER (WHERE e.state = 'released'), 0)  AS released_lifetime,
       COALESCE((SELECT sum(amount) FROM payouts p
                 WHERE p.seller_id = s.id AND p.status IN ('sent','processing')), 0) AS paid_out
FROM sellers s LEFT JOIN escrow_holds e ON e.seller_id = s.id
GROUP BY s.id;

CREATE VIEW v_platform_revenue AS
SELECT date_trunc('day', created_at) AS day, kind, sum(amount) AS total
FROM ledger_entries
WHERE kind IN ('commission','payment_fee')
GROUP BY 1,2 ORDER BY 1 DESC;

-- ============================================================================
--  12. ROW LEVEL SECURITY (фурӯшанда танҳо маълумоти худ)
-- ============================================================================
ALTER TABLE orders           ENABLE ROW LEVEL SECURITY;
ALTER TABLE products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE escrow_holds     ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts          ENABLE ROW LEVEL SECURITY;

-- API бо `SET app.current_user_id = '<uuid>'` кор мекунад
CREATE POLICY p_orders_buyer ON orders FOR SELECT
  USING (buyer_id = current_setting('app.current_user_id', true)::uuid);
CREATE POLICY p_manager_all ON orders FOR ALL
  USING (current_setting('app.current_role', true) IN ('admin','super_admin','manager'));

CREATE POLICY p_payout_seller ON payouts FOR SELECT
  USING (seller_id IN (SELECT id FROM sellers
                       WHERE owner_user_id = current_setting('app.current_user_id', true)::uuid));
CREATE POLICY p_admin_payout ON payouts FOR ALL
  USING (current_setting('app.current_role', true) IN ('admin','super_admin'));

-- ============================================================================
--  13. SEED — маълумоти ибтидоӣ
-- ============================================================================
INSERT INTO categories (name_tj, name_ru, slug, commission_rate, sort_order) VALUES
 ('Либос ва пойафзол','Одежда и обувь','libos-poyafzol',0.10,1),
 ('Электроника','Электроника','elektronika',0.05,2),
 ('Хӯрок ва нӯшокӣ','Продукты и напитки','hurok',0.06,3),
 ('Кӯдакон ва бозичаҳо','Детям и игрушки','kudakon',0.08,4),
 ('Хона ва рӯзгор','Дом и быт','hona',0.08,5),
 ('Косметика','Косметика','kosmetika',0.12,6);

INSERT INTO commission_rules (scope, rate, manager_bonus_rate, payment_fee_rate)
VALUES ('global', 0.0800, 0.1500, 0.0150);

INSERT INTO settings (key, value) VALUES
 ('escrow.auto_release_days', '7'),
 ('escrow.four_eye_threshold_tjs', '2000'),
 ('payout.min_amount_tjs', '100'),
 ('payout.allowance_per_24h', '1'),
 ('order.seller_ship_window_hours', '72'),
 ('dispute.sla_hours', '24'),
 ('app.supported_locales', '["tj","ru"]');

INSERT INTO feature_flags (key, enabled, rollout_pct) VALUES
 ('group_buy', true, 100),
 ('referral', false, 0),
 ('gamification_garden', false, 0),
 ('flash_deal', false, 0),
 ('cashback', false, 0);

-- ============================================================================
--  14. API HELPERS (баъд аз ҳамаи ҷадвалҳо — вагарна «relation orders does not exist»)
-- ============================================================================
-- Функсияи ҷустуҷӯи аккаунт аз рӯи ҳар формати рақам (барои API)
CREATE OR REPLACE FUNCTION find_user_by_phone(p_phone text)
RETURNS TABLE (user_id uuid, full_name text, orders_count bigint, created_at timestamptz)
LANGUAGE sql STABLE AS $$
    SELECT u.id, u.full_name,
           (SELECT count(*) FROM orders o WHERE o.buyer_id = u.id),
           u.created_at
      FROM users u
      JOIN auth_identities ai ON ai.user_id = u.id
     WHERE ai.provider = 'phone'
       AND ai.provider_uid = normalize_phone(p_phone)::text
     LIMIT 1;
$$;
