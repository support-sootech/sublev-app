import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ootech/services/dio_interceptor.dart';
import 'package:ootech/env.dart';

class DioCustom {
  final _dio = Dio();

  DioCustom() {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };

    _dio.options.baseUrl = Env.apiBaseUrl; // <-- agora vem do dart-define
    _dio.interceptors.add(DioInterceptor());
  }

  Dio get dio => _dio;
}
