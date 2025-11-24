import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/etiqueta_avulsa_models.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/repositories/entrada_materiais_repository.dart';
import 'package:ootech/repositories/material_repository.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class EtiquetaRepository {
  final DioCustom service;
  final NetworkAccess networkAccess;
  final UserSharedPreferencesRepository userSharedPreferencesRepository;
  final EntradaMateriaisRepository entradaMateriaisRepository;
  final MaterialRepository materialRepository;

  EtiquetaRepository({
    DioCustom? service,
    NetworkAccess? networkAccess,
    UserSharedPreferencesRepository? userSharedPreferencesRepository,
    EntradaMateriaisRepository? entradaMateriaisRepository,
    MaterialRepository? materialRepository,
  })  : service = service ?? DioCustom(),
        networkAccess = networkAccess ?? NetworkAccess(),
        userSharedPreferencesRepository =
            userSharedPreferencesRepository ?? UserSharedPreferencesRepository(),
        entradaMateriaisRepository =
            entradaMateriaisRepository ?? EntradaMateriaisRepository(),
        materialRepository = materialRepository ?? MaterialRepository();

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
      throw CustomException(message: handleDioError(dioErr));
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
      final errorMessage = handleDioError(dioErr);
      debugPrint('ERRoR 1: $errorMessage');
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return etiquetaModel;
  }

  Future<AvulsaResponse> criarEtiquetaAvulsaComFracionamento(
      EtiquetaAvulsaRequest request) async {
    final idMaterial = await _criarMaterialBase(request);
    final etiquetas = await materialRepository.fracionaMaterial(
      idMaterial: idMaterial,
      qtdFracionada: request.quantidade,
      tipo: 'UNIDADE',
    );

    final items = etiquetas
        .map((e) => EtiquetaAvulsaItem.fromJson(e.toJson()))
        .toList();
    final ids = etiquetas
        .map((e) => e.idEtiquetas ?? 0)
        .where((id) => id > 0)
        .toList();

    return AvulsaResponse(success: true, ids: ids, data: items);
  }

  Future<int> _criarMaterialBase(EtiquetaAvulsaRequest request) async {
    final payload = <String, dynamic>{
      'material_descricao': request.descricao,
      'material_cod_barras': '',
      'material_id_unidades_medidas': request.idUnidadesMedidas,
      'material_id_modo_conservacao': request.idModoConservacao,
      'material_peso': request.peso,
      'material_quantidade': request.quantidade,
      // Marca material como originado por etiqueta avulsa
      'material_fg_avulsa': 'S',
      'material_status': 'A',
      'material_dias_vencimento': 0,
      'material_dias_vencimento_aberto': 0,
    };

    if (request.validade != null) {
      final df = DateFormat('dd/MM/yyyy');
      payload['material_dt_vencimento'] = df.format(request.validade!);
      payload['material_dt_fabricacao'] = df.format(DateTime.now());
    }

    final response = await entradaMateriaisRepository.salvar(payload);
    if (response['success'] != true) {
      final msg =
          response['msg']?.toString() ?? 'Falha ao salvar material avulso';
      throw CustomException(message: msg);
    }
    final data = response['data'];
    final materialId = _extractMaterialId(data);
    if (materialId == null) {
      throw CustomException(
          message: 'ID do material não retornado pela API (etiqueta avulsa)');
    }
    return materialId;
  }

  int? _extractMaterialId(dynamic data) {
    if (data == null) return null;
    if (data is int) return data;
    if (data is String) return int.tryParse(data);
    if (data is Map) {
      for (final key in ['id_materiais', 'id', 'material']) {
        final value = data[key];
        if (value == null) continue;
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<AvulsaResponse> criarEtiquetaAvulsa(
      EtiquetaAvulsaRequest request) async {
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }
    try {
      final resp = await service.dio.post(
        '/app-etiqueta-avulsa',
        data: request.toJson(),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final map = resp.data as Map<String, dynamic>;
        if (map['success'] == true || map['ok'] == true) {
          return AvulsaResponse.fromJson(map);
        }
        final msg = map['msg'] ?? map['message'] ?? 'Falha ao criar etiqueta';
        throw CustomException(message: msg.toString());
      }
      throw CustomException(message: 'Falha HTTP ${resp.statusCode ?? ''}');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && (data['msg'] != null || data['message'] != null)) {
        throw CustomException(
            message: (data['msg'] ?? data['message']).toString());
      }
      throw CustomException(message: e.message ?? 'Erro de rede');
    }
  }
}
