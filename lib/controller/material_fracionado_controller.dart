import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/material_fracionado_vencimento_model.dart';
import 'package:ootech/repositories/material_fracionado_repository.dart';

class MaterialFracionadoController extends GetxController {
  final MaterialFracionadoRepository materialFracionadoRepository =
      MaterialFracionadoRepository();

  final _state = MaterialFracionadoState.loading.obs;
  Rx<MaterialFracionadoState> get getState => _state.value.obs;
  set setState(MaterialFracionadoState state) => _state.value = state;

  Future<MaterialFracionadoVencimentoModel>
  loadMaterialFracionadoVencimento() async {
    setState = MaterialFracionadoState.loading;
    try {
      MaterialFracionadoVencimentoModel materialFracionadoVencimentoModel =
          await materialFracionadoRepository.loadMaterialFracionadoVencimento();
      return materialFracionadoVencimentoModel;
    } catch (e) {
      throw CustomException(message: e.toString());
    }
  }
}

enum MaterialFracionadoState { loading, success, error }
