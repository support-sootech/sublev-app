import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class EtiquetaRepository {
  final service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();
  late UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();

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
      Map<String, dynamic> json = jsonDecode(dioErr.response.toString());
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
      Map<String, dynamic> json = jsonDecode(dioErr.response.toString());
      String errorMessage = json['msg'] ?? handleDioError(dioErr);
      debugPrint('ERRoR 1: $errorMessage');
      throw CustomException(message: errorMessage);
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return etiquetaModel;
  }
}
