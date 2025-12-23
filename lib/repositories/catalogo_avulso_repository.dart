
import 'package:dio/dio.dart';
import 'package:ootech/services/dio_custom.dart';

class CatalogoAvulsoRepository {
  final _dio = DioCustom().dio;

  Future<Map<String, dynamic>> listar(String busca) async {
    try {
      final response = await _dio.get('/app-catalogo-avulso', queryParameters: {
        'busca': busca,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      } else {
        return {'success': false, 'msg': 'Erro de conexão: ${e.message}'};
      }
    } catch (e) {
       return {'success': false, 'msg': 'Erro inesperado: $e'};
    }
  }

  Future<Map<String, dynamic>> salvar(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/app-catalogo-avulso-save', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      return {'success': false, 'msg': 'Erro ao salvar: ${e.message}'};
    }
  }

  Future<Map<String, dynamic>> toggleFavorito(int id, bool isFavorito) async {
    try {
      final response = await _dio.post('/app-catalogo-avulso-favorito', data: {
        'id': id,
        'favorito': isFavorito
      });
      return response.data;
    } on DioException catch (e) {
        if (e.response != null) return e.response!.data;
        return {'success': false, 'msg': 'Erro: ${e.message}'};
    }
  }
  
  Future<Map<String, dynamic>> excluir(int id) async {
    try {
      final response = await _dio.post('/app-catalogo-avulso-del', data: {'id': id});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) return e.response!.data;
      return {'success': false, 'msg': 'Erro ao excluir: ${e.message}'};
    }
  }
}
