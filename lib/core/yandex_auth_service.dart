import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    final result = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: 'com.nastya.medicalprofile',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      print('Яндекс: code не получен');
      return null;
    }

    final response = await http.post(
      Uri.parse('https://oauth.yandex.ru/token'),
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'redirect_uri': _redirectUri,
      },
    );

    print('Яндекс ответ: ${response.body}');
    final data = jsonDecode(response.body);
    return data;

  } catch (e) {
    print('Яндекс ошибка: $e');
    return null;
  }
}
}