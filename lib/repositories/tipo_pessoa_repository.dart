import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/tipo_pessoa_model.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class TipoPessoaRepository {
  final DioCustom service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();

  /// Lista todos os tipos de pessoas
  Future<List<TipoPessoaModel>> listar({String? status}) async {
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) return <TipoPessoaModel>[];

    try {
      final resp = await service.dio.get('/app-tipos-pessoas');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['success'] == true) {
          final payload = data['data'];
          if (payload is List) {
            return payload
                .whereType<Map>()
                .map((e) => TipoPessoaModel.fromJson(Map<String, dynamic>.from(e)))
                .where((tp) => status == null || tp.status == status)
                .toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TIPO-PESSOA-REPO] listar erro: $e');
    }
    return <TipoPessoaModel>[];
  }

  /// Busca um tipo de pessoa por ID
  Future<TipoPessoaModel?> buscarPorId(int id) async {
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      final resp = await service.dio.get('/tipos-pessoas-edit/$id');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['success'] == true && data['data'] != null) {
          return TipoPessoaModel.fromJson(Map<String, dynamic>.from(data['data']));
        }
        throw CustomException(message: data['msg']?.toString() ?? 'Registro não encontrado');
      }
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
    return null;
  }

  /// Salva ou atualiza um tipo de pessoa
  Future<bool> salvar(TipoPessoaModel tipoPessoa) async {
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      final payload = <String, dynamic>{
        'descricao': tipoPessoa.descricao,
        'status': tipoPessoa.status ?? 'A',
        if (tipoPessoa.id != null) 'id_tipos_pessoas': tipoPessoa.id,
      };

      final resp = await service.dio.post('/app-tipos-pessoas-save', data: payload);
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['success'] == true) {
          return true;
        }
        throw CustomException(message: data['msg']?.toString() ?? 'Falha ao salvar');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['msg'] != null) {
        throw CustomException(message: data['msg'].toString());
      }
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
    return false;
  }

  /// Deleta um tipo de pessoa (soft delete)
  Future<bool> deletar(int id) async {
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      final resp = await service.dio.get('/app-tipos-pessoas-del/$id');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['success'] == true) {
          return true;
        }
        throw CustomException(message: data['msg']?.toString() ?? 'Falha ao deletar');
      }
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
    return false;
  }
}
