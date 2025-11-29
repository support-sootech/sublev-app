import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/material_model.dart';
import 'package:ootech/services/dio_custom.dart';

class MateriaisRepository {
  final DioCustom service = DioCustom();

  Future<List<MaterialModel>> listar({String status = ''}) async {
    Future<Response<dynamic>> _fetchAppEndpoint() {
      return service.dio.get(
        '/app-materiais',
        queryParameters: {'status': status},
      );
    }

    Future<Response<dynamic>> _fetchLegacyEndpoint() {
      return service.dio.get(
        '/materiais-json',
        queryParameters: {'status': status},
      );
    }

    Future<Response<dynamic>> _fetchAppJsonEndpoint() {
      return service.dio.get(
        '/app-materiais-json',
        queryParameters: {'status': status},
      );
    }

    Response resp;
    try {
      resp = await _fetchAppEndpoint();
      if (_isHtml404(resp)) {
        resp = await _fetchAppJsonEndpoint();
      }
      if (_isHtml404(resp)) {
        resp = await _fetchLegacyEndpoint();
      }
    } on DioException catch (e) {
      if (_isHtml404(e.response)) {
        try {
          resp = await _fetchAppJsonEndpoint();
          if (_isHtml404(resp)) {
            resp = await _fetchLegacyEndpoint();
          }
        } catch (e2) {
          resp = await _fetchLegacyEndpoint();
        }
      } else {
        throw CustomException(message: e.message ?? 'Erro de rede');
      }
    }

    if (resp.statusCode == 200) {
      final data = resp.data;
      if (data is Map) {
        if (data.containsKey('success') && data['success'] != true) {
          throw CustomException(
            message:
                (data['msg'] ?? data['message'] ?? 'Erro no servidor').toString(),
          );
        }
        final payload = data['data'] ?? data;
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } else if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return <MaterialModel>[];
  }

  bool _isHtml404(Response? resp) {
    if (resp == null) return false;
    final data = resp.data;
    if (resp.statusCode == 404) return true;
    if (data is String && data.contains('<html')) return true;
    return false;
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
