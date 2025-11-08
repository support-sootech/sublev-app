import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_fracionado_vencimento_model.dart';
import 'package:ootech/repositories/material_fracionado_repository.dart';

class MaterialFracionadoVencimentoController extends GetxController {
  final MaterialFracionadoRepository materialFracionadoRepository =
      MaterialFracionadoRepository();

  final _state = MaterialFracionadoVencimentoState.loading.obs;
  Rx<MaterialFracionadoVencimentoState> get getState => _state.value.obs;
  set setState(MaterialFracionadoVencimentoState state) => _state.value = state;

  final _listaEtiquetas = <EtiquetaModel>[].obs;
  RxList<EtiquetaModel> get getListaEtiquetdas => _listaEtiquetas;

  Future<MaterialFracionadoVencimentoModel>
  loadMaterialFracionadoVencimento() async {
    setState = MaterialFracionadoVencimentoState.loading;
    try {
      MaterialFracionadoVencimentoModel materialFracionadoVencimentoModel =
          await materialFracionadoRepository.loadMaterialFracionadoVencimento();
      return materialFracionadoVencimentoModel;
    } catch (e) {
      debugPrint("ERRO: ${e.toString()}}");
      //throw CustomException(message: e.toString());
      return MaterialFracionadoVencimentoModel();
    }
  }

  Future listaMaterialFracionadoVencimento({required String filtro}) async {
    setState = MaterialFracionadoVencimentoState.loading;
    try {
      _listaEtiquetas.clear();
      _listaEtiquetas.value = await materialFracionadoRepository
          .listaMaterialFracionadoVencimento(filtro: filtro);
      _listaEtiquetas.refresh();
      setState = MaterialFracionadoVencimentoState.success;
    } catch (e) {
      debugPrint("ERRO: ${e.toString()}");
      _listaEtiquetas.clear();
      _listaEtiquetas.refresh();
      setState = MaterialFracionadoVencimentoState.success;
    }
  }
}

enum MaterialFracionadoVencimentoState { loading, success, error }
