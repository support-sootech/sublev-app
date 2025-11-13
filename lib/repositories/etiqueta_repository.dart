import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class EtiquetaRepository {
  final service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();
  late UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();

  // ========= ORIGINAIS =========
  Future<EtiquetaModel> loadEtiqueta({required String codigo}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    EtiquetaModel etiquetaModel = EtiquetaModel();
    try {
      final endPoint = "/app-etiqueta-info/$codigo";
      final response = await service.dio.get(endPoint);
      debugPrint("ETIQUETA: ${response.data.toString()}");

      if (response.data['success'] == true) {
        etiquetaModel = EtiquetaModel.fromJson(response.data['data']);
      } else {
        String errorMessage =
            response.data?['msg'] ?? "Erro desconhecido do servidor";
        throw CustomException(message: errorMessage);
      }
    } on DioException catch (dioErr) {
      Map<String, dynamic> json = {};
      try {
        json = dioErr.response?.data is String
            ? jsonDecode(dioErr.response?.data)
            : (dioErr.response?.data ?? {});
      } catch (_) {}
      String errorMessage = json['msg'] ?? handleDioError(dioErr);
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return etiquetaModel;
  }

  Future<List<EtiquetaModel>> listaEtiquetas() async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    List<EtiquetaModel> etiquetaModel = [];
    try {
      final endPoint = "/app-etiquetas";
      final response = await service.dio.get(endPoint);

      if (response.data['success'] == true && response.statusCode == 200) {
        etiquetaModel = (response.data['data'] as List).map((e) {
          return EtiquetaModel.fromJson(e);
        }).toList();
      } else {
        String errorMessage =
            response.data?['msg'] ?? "Erro desconhecido do servidor";
        debugPrint('ERRoR: $errorMessage');
        throw CustomException(message: errorMessage);
      }
    } on DioException catch (dioErr) {
      Map<String, dynamic> json = {};
      try {
        json = dioErr.response?.data is String
            ? jsonDecode(dioErr.response?.data)
            : (dioErr.response?.data ?? {});
      } catch (_) {}
      String errorMessage = json['msg'] ?? handleDioError(dioErr);
      debugPrint('ERRoR 1: $errorMessage');
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return etiquetaModel;
  }

  // ========= UNIDADES DE MEDIDA =========
  Future<List<UnidadeMedidaModel>> listaUnidadesMedidas({String status = 'A'}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      final endPoint = "/app-unidades-medidas";
      final response = await service.dio.get(endPoint, queryParameters: {'status': status});

      if (response.statusCode == 200 && response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data.map((e) => UnidadeMedidaModel.fromJson(e)).toList();
      }

      if (response.statusCode == 200 && response.data is List) {
        final data = response.data as List;
        return data.map((e) => UnidadeMedidaModel.fromJson(e)).toList();
      }

      String errorMessage =
          (response.data is Map ? response.data['msg'] : null) ??
          "Erro ao carregar unidades de medida";
      throw CustomException(message: errorMessage);
    } on DioException catch (dioErr) {
      Map<String, dynamic> json = {};
      try {
        json = dioErr.response?.data is String
            ? jsonDecode(dioErr.response?.data)
            : (dioErr.response?.data ?? {});
      } catch (_) {}
      String errorMessage = json['msg'] ?? handleDioError(dioErr);
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  // ========= NOVO: MODO DE CONSERVAÇÃO =========
  Future<List<ModoConservacaoModel>> listaModosConservacao({String status = 'A'}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      // 1) tenta rota app
      final endPoint = "/app-modo-conservacao";
      Response response = await service.dio.get(endPoint, queryParameters: {'status': status});

      // fallback para rota legacy (POST) se necessário
      if (response.statusCode != 200) {
        response = await service.dio.post("/modo-conservacao-json", data: {"status": status});
      }

      if (response.statusCode == 200 && response.data is Map) {
        final data = (response.data['data'] ?? []) as List;
        return data.map((e) => ModoConservacaoModel.fromJson(e)).toList();
      }

      if (response.statusCode == 200 && response.data is List) {
        final data = response.data as List;
        return data.map((e) => ModoConservacaoModel.fromJson(e)).toList();
      }

      String errorMessage =
          (response.data is Map ? response.data['msg'] : null) ??
          "Erro ao carregar modos de conservação";
      throw CustomException(message: errorMessage);
    } on DioException catch (dioErr) {
      Map<String, dynamic> json = {};
      try {
        json = dioErr.response?.data is String
            ? jsonDecode(dioErr.response?.data)
            : (dioErr.response?.data ?? {});
      } catch (_) {}
      String errorMessage = json['msg'] ?? handleDioError(dioErr);
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  // ========= CRIAR ETIQUETA AVULSA =========
  /// Retorna a lista de etiquetas criadas (se o backend enviar), senão lista vazia.
  Future<List<EtiquetaModel>> criarEtiquetaAvulsa(EtiquetaAvulsaRequest req) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    try {
      final endPoint = "/app-etiqueta-avulsa";
      final response = await service.dio.post(endPoint, data: req.toJson());

      if (response.statusCode == 200 && response.data is Map && response.data['success'] == true) {
        if (response.data['data'] is List) {
          return (response.data['data'] as List).map((e) => EtiquetaModel.fromJson(e)).toList();
        }
        return <EtiquetaModel>[];
      }

      if (response.statusCode == 200 && response.data is Map && response.data['ok'] == true) {
        return <EtiquetaModel>[];
      }

      String errorMessage =
          (response.data is Map
              ? (response.data['msg'] ?? response.data['message'])
              : null) ??
          "Falha ao criar etiqueta avulsa";
      throw CustomException(message: errorMessage);
    } on DioException catch (dioErr) {
      Map<String, dynamic> json = {};
      try {
        json = dioErr.response?.data is String
            ? jsonDecode(dioErr.response?.data)
            : (dioErr.response?.data ?? {});
      } catch (_) {}
      String errorMessage = json['msg'] ?? json['message'] ?? handleDioError(dioErr);
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }
}
