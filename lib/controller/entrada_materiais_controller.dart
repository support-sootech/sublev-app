import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ootech/models/option_model.dart';
import 'package:ootech/repositories/combos_repository.dart';
import 'package:ootech/repositories/modo_conservacao_repository.dart';
import 'package:ootech/repositories/unidades_repository.dart';

class EntradaMateriaisController extends GetxController {
  final CombosRepository combosRepository;
  final UnidadesRepository unidadesRepository;
  final ModoConservacaoRepository modoConservacaoRepository;

  // Evita recarga duplicada dos combos durante o ciclo de vida desta instância.
  bool _combosLoadedOnce = false; // era static, removido para evitar reuso incorreto entre telas
  bool _loadingCombos = false; // lock de concorrência

  EntradaMateriaisController({
    CombosRepository? combosRepository,
    UnidadesRepository? unidadesRepository,
    ModoConservacaoRepository? modoConservacaoRepository,
  })  : combosRepository = combosRepository ?? CombosRepository(),
        unidadesRepository = unidadesRepository ?? UnidadesRepository(),
        modoConservacaoRepository =
            modoConservacaoRepository ?? ModoConservacaoRepository();

  final RxList<OptionModel> categorias = <OptionModel>[].obs;
  final RxList<OptionModel> fornecedores = <OptionModel>[].obs;
  final RxList<OptionModel> fabricantes = <OptionModel>[].obs;
  final RxList<OptionModel> marcas = <OptionModel>[].obs;
  final RxList<OptionModel> condicoesEmbalagem = <OptionModel>[].obs;
  final RxList<OptionModel> unidades = <OptionModel>[].obs;
  final RxList<OptionModel> modosConservacao = <OptionModel>[].obs;

  final Rx<OptionModel?> categoriaSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> fornecedorSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> fabricanteSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> marcaSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> condicaoEmbalagemSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> unidadeSel = Rx<OptionModel?>(null);
  final Rx<OptionModel?> modoConservacaoSel = Rx<OptionModel?>(null);

  final RxBool categoriasLoading = false.obs;
  final RxBool fornecedoresLoading = false.obs;
  final RxBool fabricantesLoading = false.obs;
  final RxBool marcasLoading = false.obs;
  final RxBool condicoesLoading = false.obs;
  final RxBool unidadesLoading = false.obs;
  final RxBool modosLoading = false.obs;

  // Controle de bloqueio de campos (preenchidos via catálogo)
  final RxBool diasVencimentoLocked = false.obs;
  final RxBool diasVencimentoAbertoLocked = false.obs;
  final RxBool fabricanteLocked = false.obs;
  final RxBool marcaLocked = false.obs;
  final RxBool categoriaLocked = false.obs;

  void lockFields(bool locked) {
    diasVencimentoLocked.value = locked;
    diasVencimentoAbertoLocked.value = locked;
    fabricanteLocked.value = locked;
    marcaLocked.value = locked;
    categoriaLocked.value = locked;
  }

  Future<void> loadCombos() async {
    final t0 = DateTime.now();
    if (_loadingCombos) {
      if (kDebugMode) debugPrint('[COMBOS] loadCombos ignorado: já em execução');
      return;
    }
    if (_combosLoadedOnce) {
      if (kDebugMode) debugPrint('[COMBOS] loadCombos ignorado: já carregado anteriormente');
      return;
    }
    _loadingCombos = true;
    if (kDebugMode) debugPrint('[COMBOS] Iniciando carga inicial...');
    try {
      final futures = <Future<void>>[
        _timeWrap(_loadCategorias, 'categorias'),
        _timeWrap(_loadFornecedores, 'fornecedores'),
        _timeWrap(_loadFabricantes, 'fabricantes'),
        _timeWrap(_loadMarcas, 'marcas'),
        _timeWrap(_loadCondicoes, 'condicoes_embalagem'),
        _timeWrap(_loadUnidades, 'unidades_medidas'),
        _timeWrap(_loadModosConservacao, 'modos_conservacao'),
      ];
      await Future.wait(futures);
      _combosLoadedOnce = true;
      if (kDebugMode) {
        debugPrint('[COMBOS] Carga completa em ${DateTime.now().difference(t0).inMilliseconds} ms');
        debugPrint('[COMBOS] Resumo tamanhos => categorias=${categorias.length} fornecedores=${fornecedores.length} fabricantes=${fabricantes.length} marcas=${marcas.length} condicoes=${condicoesEmbalagem.length} unidades=${unidades.length} modos=${modosConservacao.length}');
      }
    } finally {
      _loadingCombos = false;
    }
  }

  // Lazy load individual combos (apenas se ainda não carregados / lista vazia).
  Future<void> ensureCategoriasLoaded() async {
    if (categorias.isNotEmpty || categoriasLoading.value) return;
    await _timeWrap(_loadCategorias, 'categorias(lazy)');
  }
  Future<void> ensureFornecedoresLoaded() async {
    if (fornecedores.isNotEmpty || fornecedoresLoading.value) return;
    await _timeWrap(_loadFornecedores, 'fornecedores(lazy)');
  }
  Future<void> ensureFabricantesLoaded() async {
    if (fabricantes.isNotEmpty || fabricantesLoading.value) return;
    await _timeWrap(_loadFabricantes, 'fabricantes(lazy)');
  }
  Future<void> ensureMarcasLoaded() async {
    if (marcas.isNotEmpty || marcasLoading.value) return;
    await _timeWrap(_loadMarcas, 'marcas(lazy)');
  }
  Future<void> ensureCondicoesEmbalagemLoaded() async {
    if (condicoesEmbalagem.isNotEmpty || condicoesLoading.value) return;
    await _timeWrap(_loadCondicoes, 'condicoes_embalagem(lazy)');
  }
  Future<void> ensureUnidadesLoaded() async {
    if (unidades.isNotEmpty || unidadesLoading.value) return;
    await _timeWrap(_loadUnidades, 'unidades_medidas(lazy)');
  }
  Future<void> ensureModosConservacaoLoaded() async {
    if (modosConservacao.isNotEmpty || modosLoading.value) return;
    await _timeWrap(_loadModosConservacao, 'modos_conservacao(lazy)');
  }

  // Conjunto mínimo para tela de inclusão (evita carga de todas as listas).
  Future<void> ensureMinimalCombosLoaded() async {
    // Categorias, unidades e modos de conservação são usados cedo.
    await Future.wait([
      ensureCategoriasLoaded(),
      ensureUnidadesLoaded(),
      ensureModosConservacaoLoaded(),
    ]);
  }

  // Força recarga ignorando flag (ex: usuário toca refresh manual).
  Future<void> forceReloadCombos() async {
    final t0 = DateTime.now();
    if (_loadingCombos) {
      if (kDebugMode) debugPrint('[COMBOS] forceReload ignorado: já em execução');
      return;
    }
    _loadingCombos = true;
    if (kDebugMode) debugPrint('[COMBOS] Forçando recarga de todos os combos...');
    try {
      final futures = <Future<void>>[
        _timeWrap(_loadCategorias, 'categorias'),
        _timeWrap(_loadFornecedores, 'fornecedores'),
        _timeWrap(_loadFabricantes, 'fabricantes'),
        _timeWrap(_loadMarcas, 'marcas'),
        _timeWrap(_loadCondicoes, 'condicoes_embalagem'),
        _timeWrap(_loadUnidades, 'unidades_medidas'),
        _timeWrap(_loadModosConservacao, 'modos_conservacao'),
      ];
      await Future.wait(futures);
      if (kDebugMode) {
        debugPrint('[COMBOS] forceReload completo em ${DateTime.now().difference(t0).inMilliseconds} ms');
        debugPrint('[COMBOS] Após reload => categorias=${categorias.length} fornecedores=${fornecedores.length} fabricantes=${fabricantes.length} marcas=${marcas.length} condicoes=${condicoesEmbalagem.length} unidades=${unidades.length} modos=${modosConservacao.length}');
      }
    } finally {
      _loadingCombos = false;
    }
  }

  Future<void> _loadCategorias() async {
    categoriasLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await combosRepository.listarCategorias();
      categorias.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] categorias carregadas (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
    } catch (e) {
      if (kDebugMode) debugPrint('loadCategorias erro: $e');
    } finally {
      categoriasLoading.value = false;
    }
  }

  Future<void> _loadFornecedores() async {
    fornecedoresLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await combosRepository.listarFornecedores();
      fornecedores.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] fornecedores carregados (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
    } catch (e) {
      if (kDebugMode) debugPrint('loadFornecedores erro: $e');
    } finally {
      fornecedoresLoading.value = false;
    }
  }

  Future<void> _loadFabricantes() async {
    fabricantesLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await combosRepository.listarFabricantes();
      fabricantes.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] fabricantes carregados (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
      // Se a seleção atual não está mais presente (ex: fabricante sem empresa), limpar seleção
      if (fabricanteSel.value != null &&
          !fabricantes.any((f) => f.id == fabricanteSel.value!.id)) {
        fabricanteSel.value = null;
      }
      // Log detalhado para diagnosticar problema de ID (422 Fabricante não encontrado)
      if (fabricantes.isEmpty) {
        if (kDebugMode) debugPrint('[FABRICANTES] Lista vazia após carga.');
      } else {
        if (kDebugMode) {
          debugPrint('[FABRICANTES] Itens carregados (${fabricantes.length}):');
          for (final f in fabricantes) {
            debugPrint('  - id=${f.id} descricao="${f.descricao}"');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadFabricantes erro: $e');
    } finally {
      fabricantesLoading.value = false;
    }
  }

  Future<void> _loadMarcas() async {
    marcasLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await combosRepository.listarMarcas();
      marcas.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] marcas carregadas (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
    } catch (e) {
      if (kDebugMode) debugPrint('loadMarcas erro: $e');
    } finally {
      marcasLoading.value = false;
    }
  }

  Future<void> _loadCondicoes() async {
    condicoesLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await combosRepository.listarCondicoesEmbalagem();
      condicoesEmbalagem.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] condicoes_embalagem carregadas (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
    } catch (e) {
      if (kDebugMode) debugPrint('loadCondicoes erro: $e');
    } finally {
      condicoesLoading.value = false;
    }
  }

  Future<void> _loadUnidades() async {
    unidadesLoading.value = true;
    try {
      final t = DateTime.now();
      final list = await unidadesRepository.listarAsOptionModel();
      unidades.assignAll(list);
      if (kDebugMode) debugPrint('[COMBOS] unidades_medidas carregadas (${list.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
    } catch (e) {
      if (kDebugMode) debugPrint('loadUnidades erro: $e');
    } finally {
      unidadesLoading.value = false;
    }
  }

  Future<void> _loadModosConservacao() async {
    modosLoading.value = true;
    try {
      final t = DateTime.now();
      // Usa status vazio para refletir paridade web (trazer todos exceto descartados)
      final modos = await modoConservacaoRepository.listar(status: '');
      modosConservacao.assignAll(
        modos
            .map((m) => OptionModel(
                  id: m.id ?? 0,
                  descricao: m.descricao ?? '',
                ))
            .toList(),
      );
      if (kDebugMode) debugPrint('[COMBOS] modos_conservacao carregados (${modos.length}) em ${DateTime.now().difference(t).inMilliseconds} ms');
      if (modos.isEmpty && kDebugMode) {
        debugPrint('[COMBOS] AVISO: modos_conservacao vazio após carga com status=""');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadModos erro: $e');
    } finally {
      modosLoading.value = false;
    }
  }

  Future<void> _timeWrap(Future<void> Function() fn, String label) async {
    final t0 = DateTime.now();
    if (kDebugMode) debugPrint('[COMBOS] Iniciando $label ...');
    await fn();
    if (kDebugMode) debugPrint('[COMBOS] Finalizado $label em ${DateTime.now().difference(t0).inMilliseconds} ms');
  }

  void resetSelecoes() {
    categoriaSel.value = null;
    fornecedorSel.value = null;
    fabricanteSel.value = null;
    marcaSel.value = null;
    condicaoEmbalagemSel.value = null;
    unidadeSel.value = null;
    modoConservacaoSel.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) debugPrint('[EntradaMateriaisController] onInit hash=${identityHashCode(this)}');
  }

  @override
  void onClose() {
    if (kDebugMode) debugPrint('[EntradaMateriaisController] onClose hash=${identityHashCode(this)}');
    super.onClose();
  }
}
