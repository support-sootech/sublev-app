import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ootech/services/dio_interceptor.dart';

class DioCustom {
  final _dio = Dio();

  DioCustom() {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };
    _dio.options.baseUrl = _baseUrl;
    // Timeouts para evitar travas longas em cold start (reduzidos de padrões infinitos)
    _dio.options.connectTimeout = const Duration(seconds: 8);
    _dio.options.receiveTimeout = const Duration(seconds: 12);
    _dio.options.sendTimeout = const Duration(seconds: 12);
    _dio.interceptors.add(DioInterceptor());
  }

  Dio get dio => _dio;
}

const _defaultBaseUrl = "https://ootech.com.br";
final String _baseUrl = _resolveBaseUrl();

String _resolveBaseUrl() {
  // Só tenta ler dotenv se já estiver inicializado para evitar NotInitializedError.
  if (dotenv.isInitialized) {
    final envUrl = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
  }

  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (apiBaseUrl.isNotEmpty) return apiBaseUrl;

  const flutterEnv =
      String.fromEnvironment('FLUTTER_ENV', defaultValue: 'production');

  const envBaseUrls = {
    'development': 'http://192.168.3.38:8000',
    'production': _defaultBaseUrl,
  };

  return envBaseUrls[flutterEnv] ?? _defaultBaseUrl;
}
