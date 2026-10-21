import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';

/// Why a tutor request failed, mapped to a message the learner can act on.
enum TutorErrorKind {
  notConfigured,
  offline,
  timeout,
  rateLimited,
  modelUnavailable,
  upstream,
  badResponse,
  unknown,
}

class TutorException implements Exception {
  TutorException(this.kind, this.message, {this.detail});

  final TutorErrorKind kind;

  /// Safe, user-facing text. Never contains keys or stack traces.
  final String message;

  /// Optional technical hint for the debug panel (still secret-free).
  final String? detail;

  @override
  String toString() => 'TutorException(${kind.name}): $message';
}

/// HTTP client for the ZLOY.AI FastAPI backend.
///
/// The OpenRouter API key is *never* present here — it lives only in the
/// backend environment. This client only knows a base URL.
class BackendClient {
  BackendClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Uri _uri(String path) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Lightweight connectivity + configuration probe used by Settings.
  Future<BackendHealth> health() async {
    if (!isConfigured) {
      throw TutorException(
        TutorErrorKind.notConfigured,
        'No backend URL configured yet.',
      );
    }
    try {
      final res = await _http.get(_uri('/api/v1/health')).timeout(timeout);
      if (res.statusCode != 200) {
        throw _mapStatus(res.statusCode, _bodyText(res));
      }
      final json = _decode(_bodyText(res));
      return BackendHealth(
        ok: json['status'] == 'ok',
        provider: json['provider'] as String? ?? 'unknown',
        model: json['model'] as String? ?? 'unknown',
        mock: json['mock'] as bool? ?? false,
      );
    } on TutorException {
      rethrow;
    } catch (e) {
      throw _mapException(e);
    }
  }

  /// Grammar correction + explanation for a single learner sentence.
  Future<TutorReply> correct({
    required String text,
    required UserProfile profile,
    required AppSettings settings,
    List<ChatMessage> history = const [],
  }) async {
    final body = <String, Object?>{
      'text': text,
      'target_language': profile.targetLanguage.code,
      'explanation_language': profile.explanationLanguage.code,
      'level': profile.level.id,
      'personality': settings.personality.id,
      'profanity': settings.profanityEnabled,
      'learning_style': profile.learningStyle.id,
      'goals': profile.goals.map((g) => g.id).toList(),
      'history': history
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList(),
    };
    return _postTutor('/api/v1/tutor/correct', body);
  }

  /// Free-form conversation with the tutor.
  Future<TutorReply> chat({
    required String message,
    required UserProfile profile,
    required AppSettings settings,
    List<ChatMessage> history = const [],
  }) async {
    final body = <String, Object?>{
      'message': message,
      'target_language': profile.targetLanguage.code,
      'explanation_language': profile.explanationLanguage.code,
      'level': profile.level.id,
      'personality': settings.personality.id,
      'profanity': settings.profanityEnabled,
      'learning_style': profile.learningStyle.id,
      'goals': profile.goals.map((g) => g.id).toList(),
      'history': history
          .where((m) => m.source != TutorSource.mock)
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList(),
    };
    return _postTutor('/api/v1/tutor/chat', body);
  }

  Future<TutorReply> _postTutor(String path, Map<String, Object?> body) async {
    if (!isConfigured) {
      throw TutorException(
        TutorErrorKind.notConfigured,
        'The AI backend is not configured. Add your backend URL in Settings, '
        'or use the offline checker.',
      );
    }
    try {
      final res = await _http
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
      if (res.statusCode != 200) {
        throw _mapStatus(res.statusCode, _bodyText(res));
      }
      final json = _decode(_bodyText(res));
      final reply = TutorReply.fromJson(json, fallbackSource: TutorSource.ai);
      if (reply.reply.trim().isEmpty) {
        throw TutorException(
          TutorErrorKind.badResponse,
          'The backend returned an empty answer. Try again.',
        );
      }
      return reply;
    } on TutorException {
      rethrow;
    } catch (e) {
      throw _mapException(e);
    }
  }

  /// Always decode as UTF-8: the http package falls back to latin-1 when the
  /// server omits `charset`, which would mangle Tajik and Russian text.
  String _bodyText(http.Response res) {
    try {
      return utf8.decode(res.bodyBytes, allowMalformed: true);
    } catch (_) {
      return res.body;
    }
  }

  Map<String, Object?> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
      throw const FormatException('Expected a JSON object');
    } on FormatException {
      throw TutorException(
        TutorErrorKind.badResponse,
        'The backend sent a response this app could not read.',
      );
    }
  }

  TutorException _mapStatus(int status, String body) {
    String? detail;
    String? code;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final d = decoded['detail'];
        if (d is String) {
          detail = d;
        } else if (d is Map) {
          detail = d['message'] as String?;
          code = d['code'] as String?;
        }
      }
    } catch (_) {
      // Non-JSON error body; ignore.
    }

    switch (status) {
      case 429:
        return TutorException(
          TutorErrorKind.rateLimited,
          detail ??
              'The tutor is rate-limited right now. Wait a moment and retry.',
        );
      case 503:
      case 502:
        return TutorException(
          TutorErrorKind.modelUnavailable,
          detail ??
              'The AI model is unavailable. Try again, or use the offline '
                  'checker.',
        );
      case 504:
        return TutorException(
          TutorErrorKind.timeout,
          'The AI took too long to answer. Try a shorter message.',
        );
      case 401:
      case 403:
        return TutorException(
          TutorErrorKind.upstream,
          'The backend rejected its AI provider credentials. '
          'The API key needs to be configured on the server.',
          detail: code,
        );
      case 422:
        return TutorException(
          TutorErrorKind.badResponse,
          detail ?? 'That message was rejected as invalid.',
        );
      default:
        return TutorException(
          TutorErrorKind.unknown,
          detail ?? 'The tutor is unavailable (HTTP $status).',
        );
    }
  }

  TutorException _mapException(Object e) {
    if (e is TimeoutException) {
      return TutorException(
        TutorErrorKind.timeout,
        'The request timed out. Check your connection and retry.',
      );
    }
    if (e is SocketException || e is http.ClientException) {
      return TutorException(
        TutorErrorKind.offline,
        'Cannot reach the backend. Check your internet connection or the '
        'backend URL in Settings.',
        detail: e.runtimeType.toString(),
      );
    }
    if (e is HandshakeException) {
      return TutorException(
        TutorErrorKind.offline,
        'Secure connection to the backend failed (TLS). '
        'Check the backend URL certificate.',
      );
    }
    return TutorException(
      TutorErrorKind.unknown,
      'Something went wrong while contacting the tutor. Please retry.',
      detail: e.toString(),
    );
  }

  void dispose() => _http.close();
}

class BackendHealth {
  const BackendHealth({
    required this.ok,
    required this.provider,
    required this.model,
    required this.mock,
  });

  final bool ok;
  final String provider;
  final String model;
  final bool mock;
}
