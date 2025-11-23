import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_model.dart';
import 'package:ootech/models/material_vencimento_count.dart';
import 'package:ootech/models/vencimento_detalhe.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class MaterialRepository {
  final service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();
  late UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();

  Future<List<MaterialModel>> buscarMaterial({required String filtro}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    List<MaterialModel> arr = [];
    try {
      final endPoint = "/app-materiais-info/$filtro";
      final response = await service.dio.get(endPoint);

      if (response.data['success'] == true) {
        arr = (response.data['data'] as List).map((e) {
          return MaterialModel.fromJson(e);
        }).toList();
      } else {
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return arr;
  }

  Future<List<EtiquetaModel>> fracionaMaterial({
    required int idMaterial,
    required int qtdFracionada,
    required String tipo,
  }) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    List<EtiquetaModel> arr = [];
    try {
      final endPoint = "/app-materiais-fracionar";
      final response = await service.dio.post(
        endPoint,
        data: {
          "id_materiais": idMaterial,
          "quantidade": qtdFracionada,
          "tipo": tipo,
        },
      );
      debugPrint("RESPONSE: ${response.data.toString()}");
      if (response.data['success'] == true) {
        arr = (response.data['arr_etiqueta'] as List).map((e) {
          return EtiquetaModel.fromJson(e);
        }).toList();
      } else {
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return arr;
  }

  Future<MaterialVencimentoCount> loadVencimentoCounts() async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    try {
      final endPoint = "/app-materiais-fracionados-vencimento";
      final response = await service.dio.get(endPoint);
      if (response.data['success'] == true) {
        return MaterialVencimentoCount.fromJson(response.data['data']);
      } else {
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  Future<List<EtiquetaModel>> loadVencimentoLista({required String acaoBtn}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    try {
      final endPoint = "/app-materiais-fracionados-vencimento-json/$acaoBtn"; // ex: btn_vencem_semana
      final response = await service.dio.get(endPoint);
      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        return data.map((e) => EtiquetaModel.fromJson(e)).toList();
      } else {
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  // Método unificado (shim) até existir endpoint único no backend.
  // scope: hoje|amanha|ate7|mais7
  Future<VencimentoDetalhe> loadVencimentoDetalhe({String scope = 'all', bool includeList = false}) async {
    // Obtém contagens
    final countsRaw = await loadVencimentoCounts();
    VencimentoCounts counts = VencimentoCounts(
      hoje: countsRaw.vencemHoje,
      amanha: countsRaw.vencemAmanha,
      ate7: countsRaw.vencemSemana,
      mais7: countsRaw.vencemMaisUmaSemana,
    );
    List<EtiquetaModel> lista = [];
    if (includeList && scope != 'all') {
      final mapScopeToBtn = <String, String>{
        'hoje': 'btn_vencem_hoje',
        'amanha': 'btn_vencem_amanha',
        'ate7': 'btn_vencem_semana',
        'mais7': 'btn_vencem_mais_1_semana',
      };
      final btn = mapScopeToBtn[scope];
      if (btn != null) {
        lista = await loadVencimentoLista(acaoBtn: btn);
      }
    }
    return VencimentoDetalhe(counts: counts, scope: scope, lista: lista);
  }
}
