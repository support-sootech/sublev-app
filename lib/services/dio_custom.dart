import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ootech/services/dio_interceptor.dart';

class DioCustom {
  late final Dio _dio;

  DioCustom() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'SubLev-App/1.0.6',
      },
    ));

    _dio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    _dio.interceptors.add(DioInterceptor());
  }

  Dio get dio => _dio;
}

// Ambiente padrão (produção) com trailing slash
const _baseUrl = "https://www.ootech.com.br/";
