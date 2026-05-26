import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Регистрация ───────────────────────────────────────
  static Future<UserProfile?> register({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final uid = res.user?.id;
    if (uid == null) return null;

    final profile = UserProfile(uid: uid);
    await _client.from('users').upsert(
      profile.toMap(),
      onConflict: 'uid', // ✅
    );
    return profile;
  }

  // ─── Вход ──────────────────────────────────────────────
  static Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final uid = res.user?.id;
    if (uid == null) return null;
    return await getProfile(uid);
  }

  // ─── Выход ─────────────────────────────────────────────
  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  // ─── Получить профиль ──────────────────────────────────
  static Future<UserProfile?> getProfile(String uid) async {
    final data = await _client
        .from('users')
        .select()
        .eq('uid', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  // ─── Сохранить профиль ─────────────────────────────────
  static Future<void> saveProfile(UserProfile profile) async {
    await _client
        .from('users')
        .upsert(
          profile.toMap(),
          onConflict: 'uid', // ✅
        );
  }

  // ─── Яндекс: сохранить профиль ────────────────────────
  static Future<void> saveYandexProfile({
    required String yandexUid,
    required String email,
    String? name,
    String? lastName,
  }) async {
    // ✅ Проверяем — если профиль уже есть, не перезаписываем имя/фамилию
    final existing = await getProfile(yandexUid);
    if (existing != null) return; // профиль уже есть — не трогаем

    final profile = UserProfile(
      uid: yandexUid,
      firstName: name ?? '',
      lastName: lastName ?? '',
    );
    await _client.from('users').upsert(
      profile.toMap(),
      onConflict: 'uid', // ✅
    );
  }

  // ─── Отправить OTP для сброса пароля ──────────────────
  static Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: null,
    );
  }

  // ─── Верифицировать OTP и установить новый пароль ─────
  static Future<void> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}