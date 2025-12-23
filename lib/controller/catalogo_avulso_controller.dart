import 'package:get/get.dart';
import 'package:ootech/models/catalogo_avulso_model.dart';
import 'package:ootech/repositories/catalogo_avulso_repository.dart';

class CatalogoAvulsoController extends GetxController {
  final CatalogoAvulsoRepository _repo = CatalogoAvulsoRepository();
  
  final isLoading = false.obs;
  final lista = <CatalogoAvulsoModel>[].obs;
  final filtroBusca = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Monitora filtro com debounce de 500ms
    debounce(filtroBusca, (_) => carregar(), time: const Duration(milliseconds: 500));
    carregar();
  }

  @override
  void onClose() {
    filtroBusca.value = '';
    super.onClose();
  }

  Future<void> carregar() async {
    isLoading.value = true;
    try {
      final res = await _repo.listar(filtroBusca.value);
      if (res['success'] == true && res['data'] != null) {
        final List l = res['data'];
        lista.value = l.map((e) => CatalogoAvulsoModel.fromJson(e)).toList();
      } else {
        lista.clear();
      }
    } catch (_) {
      lista.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleFavorito(CatalogoAvulsoModel item) async {
      if (item.id == null) return false;
      final old = item.favorito;
      item.favorito = !old;
      
      
      // Reordena REMOVIDO: Cliente solicitou que não reordene ao clicar (UX: item não deve pular)
      // lista.sort((a, b) => ...);
      lista.refresh(); 
      
      final res = await _repo.toggleFavorito(item.id!, item.favorito);
      
      if (res['success'] != true) {
          // Reverte visualmente se falhar
          item.favorito = old;
          lista.refresh();
          Get.snackbar('Erro', 'Não foi possível atualizar favorito');
          return false;
      }
      
      // CRITICO: Recarregar do backend para garantir que IDs, ordenação de updates e novos items estejam 100% sincronizados.
      // Isso corrige o bug de "marcar o item errado" caso a lista local esteja desatualizada.
      // await carregar(); -> REMOVIDO A PEDIDO DO CLIENTE (Era confusão visual da reordenação)
      return true;
  }
  
  Future<Map<String, dynamic>> salvarItem(Map<String, dynamic> data) async {
      final res = await _repo.salvar(data);
      return res;
  }
  
  Future<bool> excluir(int id) async {
      isLoading.value = true;
      final res = await _repo.excluir(id);
      isLoading.value = false;
      if (res['success'] == true) {
          lista.removeWhere((e) => e.id == id);
          return true;
      } else {
          Get.snackbar('Erro', res['msg'] ?? 'Falha ao excluir');
          return false;
      }
  }
}
