import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_model.dart';
import 'package:ootech/models/material_vencimento_count.dart'; // legado (counts endpoint atual)
import 'package:ootech/models/vencimento_detalhe.dart';
import 'package:ootech/repositories/material_repository.dart';

class MaterialController extends GetxController {
  final MaterialRepository materialRepository = MaterialRepository();

  final _state = MaterialBuscaState.initial.obs;
  Rx<MaterialBuscaState> get getState => _state.value.obs;
  set setState(MaterialBuscaState state) => _state.value = state;

  final _listaMateriais = <MaterialModel>[].obs;
  RxList<MaterialModel> get getListaMaterial => _listaMateriais;

  final _listaEtiquetasFracionadas = <EtiquetaModel>[].obs;
  RxList<EtiquetaModel> get getListaEtiquetasFracionadas =>
      _listaEtiquetasFracionadas;

  // Contagens de vencimento vindas do backend
  final _vencimentoCount = Rx<MaterialVencimentoCount?>(null);
  Rx<MaterialVencimentoCount?> get getVencimentoCount => _vencimentoCount;

  final _vencimentoDetalhe = Rx<VencimentoDetalhe?>(null);
  Rx<VencimentoDetalhe?> get getVencimentoDetalhe => _vencimentoDetalhe;

  Future<void> fetchVencimentoCounts() async {
    try {
      final counts = await materialRepository.loadVencimentoCounts();
      _vencimentoCount.value = counts;
    } catch (_) {
      // Silencia falha para fallback local
      _vencimentoCount.value = null;
    }
  }

  Future<void> fetchVencimentoDetalhe({String scope = 'all', bool includeList = false}) async {
    try {
      final detalhe = await materialRepository.loadVencimentoDetalhe(scope: scope, includeList: includeList);
      _vencimentoDetalhe.value = detalhe;
    } catch (_) {
      _vencimentoDetalhe.value = null;
    }
  }

  Future buscarMaterial({required String filtro}) async {
    setState = MaterialBuscaState.loading;
    try {
      _listaMateriais.clear();
      if (filtro.isNotEmpty) {
        _listaMateriais.value = await materialRepository.buscarMaterial(
          filtro: filtro,
        );
      }
      _listaMateriais.refresh();
      setState = MaterialBuscaState.success;
    } catch (e) {
      setState = MaterialBuscaState.error;
      _listaMateriais.clear();
      _listaMateriais.refresh();
      throw CustomException(message: e.toString());
    }
  }

  Future<List<EtiquetaModel>> fracionaMaterial({
    required int idMaterial,
    required int qtdFracionada,
    required String tipo,
  }) async {
    setState = MaterialBuscaState.loading;
    try {
      setState = MaterialBuscaState.success;
      List<EtiquetaModel> arr = await materialRepository.fracionaMaterial(
        idMaterial: idMaterial,
        qtdFracionada: qtdFracionada,
        tipo: tipo,
      );
      limparListaMaterial();
      return arr;
    } catch (e) {
      setState = MaterialBuscaState.error;
      throw CustomException(message: e.toString());
    }
  }

  limparListaMaterial() {
    _listaMateriais.clear();
    _listaMateriais.refresh();
  }

  Future<List<EtiquetaModel>> TesteFracionaMaterial() async {
    setState = MaterialBuscaState.loading;
    try {
      List<EtiquetaModel> arr = [];
      int num = 2;
      debugPrint("INICIO: ${DateTime.now()}");
      for (var i = 1; i <= num; i++) {
        await Future.delayed(Duration(seconds: 1), () {
          arr.add(
            EtiquetaModel(
              descricao: 'Produto ${i}',
              dtVencimento: '2025-10-20',
              dtFracionamento: '2024-07-19',
              nmSetor: 'Qualidade',
              qtdFracionada: "250",
              dsUnidadesMedidas: 'mg',
              nmPessoaAbreviado: 'Dev C',
              idEtiquetas: i,
              dsModoConservacao: 'Proteger da luz ${i}',
            ),
          );
          _listaEtiquetasFracionadas.value = arr;
          _listaEtiquetasFracionadas.refresh();
        });
      }
      debugPrint("FINAL: ${DateTime.now()}");
      setState = MaterialBuscaState.success;
      return arr;
    } catch (e) {
      setState = MaterialBuscaState.error;
      throw CustomException(message: e.toString());
    }
  }
}

enum MaterialBuscaState { initial, loading, success, error }
