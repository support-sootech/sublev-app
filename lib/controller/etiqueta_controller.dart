import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/repositories/etiqueta_repository.dart';
import 'package:ootech/repositories/material_fracionado_repository.dart';

class EtiquetaController extends GetxController {
  final EtiquetaRepository etiquetaRepository = EtiquetaRepository();
  final MaterialFracionadoRepository materialFracionadoRepository =
      MaterialFracionadoRepository();

  final _state = EtiquetaState.initial.obs;
  Rx<EtiquetaState> get getState => _state.value.obs;
  set setState(EtiquetaState state) => _state.value = state;

  final _listaEtiquetas = <EtiquetaModel>[].obs;
  RxList<EtiquetaModel> get getListaEtiquetdas => _listaEtiquetas;

  final _listaEtiquetasSelecionadas = <EtiquetaModel>[].obs;
  RxList<EtiquetaModel> get getListaEtiquetasSelecionadas =>
      _listaEtiquetasSelecionadas;

  final _msgError = "".obs;
  Rx<String> get getMsgError => _msgError;
  set setGetMsgError(String msg) => _msgError.value = msg;

  Future<EtiquetaModel> loadEtiqueta({required String codigo}) async {
    setState = EtiquetaState.loading;
    try {
      EtiquetaModel etiquetaModel = await etiquetaRepository.loadEtiqueta(
        codigo: codigo,
      );
      setState = EtiquetaState.success;

      if (!_listaEtiquetasSelecionadas.any(
        (etiqueta) => etiqueta.idEtiquetas == etiquetaModel.idEtiquetas,
      )) {
        _listaEtiquetasSelecionadas.add(etiquetaModel);
        _listaEtiquetasSelecionadas.refresh();
      }
      return etiquetaModel;
    } catch (e) {
      setState = EtiquetaState.error;
      throw CustomException(message: e.toString());
    }
  }

  Future<List<EtiquetaModel>> loadListaEtiquetas() async {
    setState = EtiquetaState.loading;
    try {
@@ -59,46 +59,47 @@ class EtiquetaController extends GetxController {
      setState = EtiquetaState.error;
      setGetMsgError = CustomException(message: e.toString()).toString();
      throw CustomException(message: e.toString());
    }
  }

  Future removeEtiquetasLista(EtiquetaModel etiquetaModel) async {
    setState = EtiquetaState.loading;
    try {
      _listaEtiquetasSelecionadas.remove(etiquetaModel);
      _listaEtiquetasSelecionadas.refresh();
      setState = EtiquetaState.success;
    } catch (e) {
      setState = EtiquetaState.error;
      setGetMsgError = CustomException(message: e.toString()).toString();
      throw CustomException(message: e.toString());
    }
  }

  Future<bool> baixaDescarteMaterialFracionado({
    required String status,
    String motivo = "",
  }) async {
    try {
      setState = EtiquetaState.loading;

      final etiquetas = List<EtiquetaModel>.from(_listaEtiquetasSelecionadas);
      for (final etiqueta in etiquetas) {
        await materialFracionadoRepository.baixaDescarteMaterialFracionado(
          idMateriaisFracionados: etiqueta.idMateriaisFracionados!,
          status: status,
          motivo: motivo,
        );
        _listaEtiquetasSelecionadas.remove(etiqueta);
      }

      _listaEtiquetasSelecionadas.refresh();
      setState = EtiquetaState.success;
      return true;
    } catch (e) {
      setState = EtiquetaState.error;
      throw CustomException(message: e.toString());
    }
  }
}

enum EtiquetaState { initial, loading, success, error }