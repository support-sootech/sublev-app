import 'package:dio/dio.dart';
import 'package:ootech/models/option_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/services/dio_custom.dart';

class UnidadesRepository {
  final DioCustom service = DioCustom();

  Future<List<UnidadeMedidaModel>> listar({String status = 'A'}) async {
    final t0 = DateTime.now();
    // Log básico antes da requisição
    // (Uso direto de print pois já existe print no arquivo para 404; manter padrão.)
    if (true) {
      print('[UNIDADES-REPO] listar status="$status" iniciando');
    }
    try {
      final resp = await service.dio.get(
        '/app-unidades-medidas',
        queryParameters: {'status': status},
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['data'] is List) {
          final list = (data['data'] as List)
              .whereType<Map>()
              .map((e) => UnidadeMedidaModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          print('[UNIDADES-REPO] listar map.data length=${list.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms');
          return list;
        }
        if (data is List) {
          final list = data
              .whereType<Map>()
              .map((e) => UnidadeMedidaModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          print('[UNIDADES-REPO] listar list length=${list.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms');
          return list;
        }
      }
    } on DioException catch (e) {
      // Se a API retornar 404 (rota inexistente), consideramos lista vazia
      if (e.response?.statusCode == 404) {
        print('UnidadesRepository.listar: 404 recebido, retornando lista vazia');
        return <UnidadeMedidaModel>[];
      }
      rethrow;
    }
    print('[UNIDADES-REPO] listar vazio dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return <UnidadeMedidaModel>[];
  }

  Future<List<OptionModel>> listarAsOptionModel({String status = 'A'}) async {
    final unidades = await listar(status: status);
    final list = unidades
        .map(
          (u) => OptionModel(
            id: u.id ?? 0,
            descricao: (u.descricao ?? u.sigla ?? '').toString(),
          ),
        )
        .toList();
    // Log após conversão
    print('[UNIDADES-REPO] listarAsOptionModel convertidos=${list.length}');
    return list;
    // Não fará log aqui pois listar já loga.
  }
}
