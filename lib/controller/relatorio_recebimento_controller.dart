import 'package:get/get.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';
import 'package:ootech/repositories/relatorio_recebimento_repository.dart';

class RelatorioRecebimentoController extends GetxController {
  final RelatorioRecebimentoRepository _repo = RelatorioRecebimentoRepository();
  final itens = <RelatorioRecebimentoItem>[].obs;
  final carregando = false.obs;
  final erro = RxnString();
  DateTime dtIni = DateTime.now().subtract(const Duration(days: 7));
  DateTime dtFim = DateTime.now();

  Future<void> carregar({bool refresh = false}) async {
    carregando.value = true;
    erro.value = null;
    try {
      final dados = await _repo.carregar(dtIni: dtIni, dtFim: dtFim);
      itens.assignAll(dados);
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  void alterarIntervalo(DateTime ini, DateTime fim) {
    dtIni = ini;
    dtFim = fim;
    carregar();
  }

  @override
  void onInit() {
    super.onInit();
    carregar();
  }
}
