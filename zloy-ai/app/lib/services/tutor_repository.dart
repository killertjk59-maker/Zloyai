import '../models/chat_models.dart';
import '../models/user_profile.dart';
import 'backend_client.dart';
import 'offline_tutor.dart';

/// Decides where a tutor answer comes from.
///
/// Rules:
/// * offline-only mode, or no backend URL  -> on-device checker (clearly
///   labelled `TutorSource.offline`)
/// * otherwise -> backend (AI or its mock provider, labelled by the backend)
///
/// A network failure is *never* silently replaced with a fake AI answer: the
/// exception is propagated so the UI can show an honest error state with a
/// retry button.
class TutorRepository {
  TutorRepository({
    required this.offline,
    BackendClient Function()? clientFactory,
  }) {
    _clientFactory = clientFactory;
  }

  final OfflineTutor offline;
  BackendClient Function()? _clientFactory;

  BackendClient? _cached;
  String? _cachedUrl;

  BackendClient? _client(AppSettings settings) {
    if (!settings.hasBackend || settings.preferOfflineOnly) return null;
    if (_cached != null && _cachedUrl == settings.backendBaseUrl) {
      return _cached;
    }
    _cachedUrl = settings.backendBaseUrl;
    final factory = _clientFactory;
    _cached = factory != null
        ? factory()
        : BackendClient(baseUrl: settings.backendBaseUrl);
    return _cached;
  }

  bool canReachBackend(AppSettings settings) => _client(settings) != null;

  Future<TutorReply> correct({
    required String text,
    required UserProfile profile,
    required AppSettings settings,
    List<ChatMessage> history = const [],
  }) async {
    final client = _client(settings);
    if (client == null) {
      return offline.buildReply(
        text: text,
        personality: settings.personality,
        explanationLanguage: profile.explanationLanguage,
        targetLanguage: profile.targetLanguage,
      );
    }
    return client.correct(
      text: text,
      profile: profile,
      settings: settings,
      history: history,
    );
  }

  /// Explicit offline fallback used by the "Check offline" button after a
  /// failed request, so the learner always has a way forward.
  TutorReply correctOffline({
    required String text,
    required UserProfile profile,
    required AppSettings settings,
  }) => offline.buildReply(
    text: text,
    personality: settings.personality,
    explanationLanguage: profile.explanationLanguage,
    targetLanguage: profile.targetLanguage,
  );

  Future<TutorReply> chat({
    required String message,
    required UserProfile profile,
    required AppSettings settings,
    List<ChatMessage> history = const [],
  }) async {
    final client = _client(settings);
    if (client == null) {
      return offline.buildReply(
        text: message,
        personality: settings.personality,
        explanationLanguage: profile.explanationLanguage,
        targetLanguage: profile.targetLanguage,
      );
    }
    return client.chat(
      message: message,
      profile: profile,
      settings: settings,
      history: history,
    );
  }

  Future<BackendHealth?> probe(AppSettings settings) async {
    final client = _client(settings);
    if (client == null) return null;
    return client.health();
  }

  void dispose() {
    _cached?.dispose();
    _cached = null;
    _cachedUrl = null;
  }
}
