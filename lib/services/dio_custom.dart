import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
    // Timeouts mais permissivos para produção
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(DioInterceptor());
  }

  Dio get dio => _dio;
}


// Ambiente padrão (produção)
const _baseUrl = "https://ootech.com.br";
