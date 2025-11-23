import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_fracionado_vencimento_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class MaterialFracionadoRepository {
  final service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();
  late UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();

  Future<MaterialFracionadoVencimentoModel>
  loadMaterialFracionadoVencimento() async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    MaterialFracionadoVencimentoModel materialFracionadoVencimentoModel =
        MaterialFracionadoVencimentoModel();

    try {
      final endPoint = "/app-materiais-fracionados-vencimento";
      final response = await service.dio.get(endPoint);

      if (response.data['success'] == true) {
        materialFracionadoVencimentoModel =
            MaterialFracionadoVencimentoModel.fromJson(response.data['data']);
      } else {
        throw CustomException(message: response.data['msg']);
      }
      return materialFracionadoVencimentoModel;
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  Future<bool> baixaDescarteMaterialFracionado({
    required int idMateriaisFracionados,
    required String status,
    String motivo = "",
  }) async {
    try {
      var isConnected = await networkAccess.checkNetworkAcess();
      if (!isConnected) {
        throw CustomException(message: "Você está sem conexão a internet!");
      }

      final endPoint = "/app-materiais-fracionados-baixa";
      final response = await service.dio.put(
        endPoint,
        data: {
          "id_materiais_fracionados": idMateriaisFracionados,
          "status": status,
          "motivo_descarte": motivo,
        },
      );
      if (response.data['success'] == true) {
        return true;
      } else {
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }

  Future<List<EtiquetaModel>> listaMaterialFracionadoVencimento({
    required String filtro,
  }) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    List<EtiquetaModel> arr = [];

    try {
      final endPoint = "/app-materiais-fracionados-vencimento-json/$filtro";
      final response = await service.dio.get(endPoint);

      if (response.data['success'] == true) {
        arr = response.data['data'].map<EtiquetaModel>((item) {
          return EtiquetaModel.fromJson(item);
        }).toList();
      } else {
        throw CustomException(message: response.data['msg']);
      }
      return arr;
    } on DioException catch (dioErr) {
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }
}
