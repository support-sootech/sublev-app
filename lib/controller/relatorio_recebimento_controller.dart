import 'dart:io';

import 'package:get/get.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';
import 'package:ootech/repositories/relatorio_recebimento_repository.dart';

class RelatorioRecebimentoController extends GetxController {
  final RelatorioRecebimentoRepository _repo = RelatorioRecebimentoRepository();
  final itens = <RelatorioRecebimentoItem>[].obs;
  final carregando = false.obs;
  final erro = RxnString();
  final dtIni = DateTime.now().subtract(const Duration(days: 7)).obs;
  final dtFim = DateTime.now().obs;
  final filtroTexto = ''.obs;
  final exportando = false.obs;
  final exportErro = RxnString();

  Future<void> carregar({bool refresh = false, String? filtroBusca}) async {
    carregando.value = true;
    erro.value = null;
    if (filtroBusca != null) {
      filtroTexto.value = filtroBusca;
    }
    try {
      final dados = await _repo.carregar(
        dtIni: dtIni.value,
        dtFim: dtFim.value,
        busca: filtroTexto.value,
      );
      itens.assignAll(dados);
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  void aplicarFiltros(DateTime ini, DateTime fim, {String? filtroBusca}) {
    dtIni.value = ini;
    dtFim.value = fim;
    carregar(filtroBusca: filtroBusca ?? filtroTexto.value);
  }

  Future<File?> gerarPdf({String? filtroBusca}) async {
    exportando.value = true;
    exportErro.value = null;
    if (filtroBusca != null) {
      filtroTexto.value = filtroBusca;
    }
    try {
      final file = await _repo.exportarPdf(
        dtIni: dtIni.value,
        dtFim: dtFim.value,
        busca: filtroTexto.value,
      );
      return file;
    } catch (e) {
      exportErro.value = e.toString();
      return null;
    } finally {
      exportando.value = false;
    }
  }
}
