import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/etiqueta_avulsa_models.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/repositories/etiqueta_repository.dart';
import 'package:ootech/repositories/modo_conservacao_repository.dart';
import 'package:ootech/repositories/unidades_repository.dart';

class EtiquetaAvulsaController extends GetxController {
  final EtiquetaRepository repository;
  final UnidadesRepository unidadesRepository;
  final ModoConservacaoRepository modosRepository;

  EtiquetaAvulsaController({
    EtiquetaRepository? repository,
    UnidadesRepository? unidadesRepository,
    ModoConservacaoRepository? modosRepository,
  })  : repository = repository ?? EtiquetaRepository(),
        unidadesRepository = unidadesRepository ?? UnidadesRepository(),
        modosRepository = modosRepository ?? ModoConservacaoRepository();

  final RxBool loadingCombos = false.obs;
  final RxList<UnidadeMedidaModel> unidades = <UnidadeMedidaModel>[].obs;
  final RxList<ModoConservacaoModel> modos = <ModoConservacaoModel>[].obs;
  // flag para sinalizar falha ao carregar combos (unidades/modos)
  final RxBool combosLoadFailed = false.obs;

  Future<void> loadCombos() async {
    loadingCombos.value = true;
    try {
      final unidadesList = await unidadesRepository.listar();
      print('loadCombos: unidadesList retornou ${unidadesList.length} itens');
      final modosList = await modosRepository.listar();
      print('loadCombos: modosList retornou ${modosList.length} itens');
      unidades.assignAll(unidadesList);
      modos.assignAll(modosList);
      combosLoadFailed.value = false;
    } catch (e) {
      // Protege a view contra erros na API (ex.: 404) evitando crash
      print('ERRO loadCombos: $e');
      try {
        print('ERRO loadCombos stack: ${e.toString()}');
      } catch (_) {}
      unidades.clear();
      modos.clear();
      combosLoadFailed.value = true;
    } finally {
      loadingCombos.value = false;
    }
  }

  Future<AvulsaResponse> criar(EtiquetaAvulsaRequest request) async {
    try {
      // Prioriza o endpoint oficial de etiquetas avulsas (garante tipo_etiqueta = "A")
      return await repository.criarEtiquetaAvulsa(request);
    } catch (e) {
      try {
        // Fallback legado para ambientes antigos (usa fracionamento padrão)
        return await repository.criarEtiquetaAvulsaComFracionamento(request);
      } catch (_) {
        throw CustomException(message: e.toString());
      }
    }
  }
}
