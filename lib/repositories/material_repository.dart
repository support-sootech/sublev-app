import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_model.dart';
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
      Map<String, dynamic> json = jsonDecode(dioErr.response.toString());
      throw CustomException(message: json['msg']);
    } on ErrorInterceptorHandler catch (errorInterceptor) {
      throw CustomException(message: errorInterceptor.toString());
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
      Map<String, dynamic> json = jsonDecode(dioErr.response.toString());
      throw CustomException(message: json['msg']);
    } on ErrorInterceptorHandler catch (errorInterceptor) {
      throw CustomException(message: errorInterceptor.toString());
    } catch (e) {
      throw CustomException(message: e.toString());
    }
    return arr;
  }
}
