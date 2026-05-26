import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class YandexAuthService {
  static const _clientId = '2959d1e3a3cf45b59fa163cdcb563cf5';
  static const _clientSecret = 'f47e35154dac48e69ec786ca25571034';
  static const _redirectUri = 'com.nastya.medicalprofile://oauth';

  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final url = 'https://oauth.yandex.ru/authorize'
          '?response_type=code'
          '&client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}';

      // Открываем браузер
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      // Ждём редирект через app_links
      final appLinks = AppLinks();
      final redirectUri = await appLinks.uriLinkStream
          .where((uri) => uri.scheme == 'com.nastya.medicalprofile')
          .first
          .timeout(const Duration(minutes: 5));

      final code = redirectUri.queryParameters['code'];
      if (code == null) return null;

      // Получаем токен
      final tokenResponse = await http.post(
        Uri.parse('https://oauth.yandex.ru/token'),
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
        },
      );

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];
      if (accessToken == null) return null;

      // Получаем данные пользователя
      final userResponse = await http.get(
        Uri.parse('https://login.yandex.ru/info?format=json'),
        headers: {'Authorization': 'OAuth $accessToken'},
      );

      final userData = jsonDecode(userResponse.body);
      final yandexUid = userData['id']?.toString();
      final email = userData['default_email']?.toString() ?? '';
      final firstName = userData['first_name']?.toString() ?? '';
      final lastName = userData['last_name']?.toString() ?? '';

      if (yandexUid == null) return null;

      // Сохраняем uid в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yandex_uid', yandexUid);

      // Сохраняем в Supabase
      await AuthService.saveYandexProfile(
        yandexUid: yandexUid,
        email: email,
        name: firstName,
        lastName: lastName,
      );

      return {
        ...tokenData,
        'uid': yandexUid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      };
    } catch (e) {
      print('Яндекс ошибка: $e');
      return null;
    }
  }
}