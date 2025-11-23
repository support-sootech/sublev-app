import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/material_model.dart';
import 'package:ootech/services/dio_custom.dart';

class MateriaisRepository {
  final DioCustom service = DioCustom();

  Future<List<MaterialModel>> listar({String status = ''}) async {
    try {
      final resp = await service.dio.get(
        '/app-materiais',
        queryParameters: {'status': status},
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final Map data = resp.data;
        if (data.containsKey('success') && data['success'] != true) {
          throw CustomException(
            message: (data['msg'] ?? data['message'] ?? 'Erro no servidor')
                .toString(),
          );
        }
        final payload = data['data'] ?? data;
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
    return <MaterialModel>[];
  }

  Future<bool> deletar(int id) async {
    try {
      Response resp;
      try {
        resp = await service.dio.get('/app-materiais-del/$id');
      } on DioException {
        resp = await service.dio.get('/materiais-del/$id');
      }
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['success'] == true) return true;
        throw CustomException(message: (data['msg'] ?? 'Falha ao deletar').toString());
      }
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
    return false;
  }
}
