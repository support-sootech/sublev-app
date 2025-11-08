import 'dart:convert';
import 'package:dio/dio.dart';

String handleDioError(DioException dioErr) {
  switch (dioErr.type) {
    case DioExceptionType.connectionTimeout:
      return "Tempo limite de conexão excedido";
    case DioExceptionType.sendTimeout:
      return "Tempo limite para envio excedido";
    case DioExceptionType.receiveTimeout:
      return "Tempo limite para recebimento excedido";
    case DioExceptionType.badResponse:
      // Erro de resposta do servidor (4xx, 5xx)
      if (dioErr.response != null) {
        try {
          final responseData = dioErr.response!.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('msg')) {
            return responseData['msg'];
          } else if (responseData is String) {
            final json = jsonDecode(responseData);
            return json['msg'] ?? "Erro do servidor";
          }
        } catch (e) {
          return "Erro ao parsear resposta de erro: $e";
        }
        return "Erro do servidor (${dioErr.response!.statusCode})";
      }
      return "Erro de resposta do servidor";
    case DioExceptionType.cancel:
      return "Requisição cancelada";
    case DioExceptionType.connectionError:
      return "Erro de conexão com o servidor";
    case DioExceptionType.badCertificate:
      return "Erro de certificado SSL";
    case DioExceptionType.unknown:
      return "Erro de conexão: Verifique sua internet e tente novamente";
  }
}
