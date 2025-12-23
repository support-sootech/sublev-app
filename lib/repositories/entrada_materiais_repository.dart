import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/services/dio_custom.dart';

class EntradaMateriaisRepository {
  final DioCustom service = DioCustom();

  Future<Map<String, dynamic>> salvar(Map<String, dynamic> payload) async {
    try {
      final resp =
          await service.dio.post("app-materiais-save", data: payload);
      return _normalizeResponse(resp.data, resp.statusCode);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return _normalizeResponse(e.response!.data, e.response?.statusCode);
      }
      throw CustomException(message: e.message ?? 'Erro na requisição');
    }
  }

  Future<Map<String, dynamic>> loadById(int id) async {
    try {
      final resp = await service.dio.get("app-materiais-edit/$id");
      if (resp.statusCode == 200 && resp.data is Map) {
        return Map<String, dynamic>.from(resp.data);
      }
      throw CustomException(message: 'Falha ao carregar material');
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Erro na requisição');
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
    }
    throw CustomException(message: 'Falha HTTP ${statusCode ?? ''}');
  }
}
