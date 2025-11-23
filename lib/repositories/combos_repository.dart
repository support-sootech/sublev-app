import 'package:flutter/foundation.dart';
import 'package:ootech/models/option_model.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class CombosRepository {
  final DioCustom service = DioCustom();
  final NetworkAccess _network = NetworkAccess();

  // Cache simples em memória com TTL por endpoint+query
  static final Map<String, _ComboCacheEntry> _cache = <String, _ComboCacheEntry>{};
  static const Duration _ttl = Duration(minutes: 10);

  void limparCache() => _cache.clear();

  String _buildKey(String endpoint, Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer(endpoint);
    for (final k in sortedKeys) {
      buffer.write('|');
      buffer.write(k);
      buffer.write('=');
      buffer.write(params[k]);
    }
    return buffer.toString();
  }

  Future<List<OptionModel>> listarCategorias({String status = ''}) {
    if (kDebugMode) debugPrint('[COMBOS-REPO] listarCategorias status="$status"');
    return _fetchOptions('/app-categorias', status: status);
  }

  Future<List<OptionModel>> listarFornecedores({String status = ''}) async {
    final t0 = DateTime.now();
    if (kDebugMode) debugPrint('[COMBOS-REPO] listarFornecedores status="$status"');
    // Busca principal com filtro explícito
    final primary = await _fetchOptions(
      '/app-fornecedores',
      status: status,
      query: {'id_tipos_pessoas': '3', 'all': '1'},
    );
    // Busca secundária sem filtro para garantir completude (alguns registros podem não vir quando filtrados)
    final secondary = await _fetchOptions(
      '/app-fornecedores',
      status: status,
      query: {'all': '1'},
    );
    // Mescla e mantém apenas id_tipos_pessoas == 3
    final all = <int, OptionModel>{};
    for (final o in [...primary, ...secondary]) {
      if (o.idTiposPessoas == null || o.idTiposPessoas == 3) {
        all[o.id] = o;
      }
    }
    if (kDebugMode) debugPrint('[COMBOS-REPO] fornecedores merged primary=${primary.length} secondary=${secondary.length} final=${all.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return all.values.toList();
  }

  Future<List<OptionModel>> listarFabricantes({String status = ''}) async {
    final t0 = DateTime.now();
    if (kDebugMode) debugPrint('[COMBOS-REPO] listarFabricantes status="$status"');
    final primary = await _fetchOptions(
      '/app-fabricantes',
      status: status,
      query: {'id_tipos_pessoas': '2', 'all': '1'},
    );
    final secondary = await _fetchOptions(
      '/app-fabricantes',
      status: status,
      query: {'all': '1'},
    );
    final all = <int, OptionModel>{};
    for (final o in [...primary, ...secondary]) {
      if (o.idTiposPessoas == null || o.idTiposPessoas == 2) {
        all[o.id] = o;
      }
    }
    if (kDebugMode) debugPrint('[COMBOS-REPO] fabricantes merged primary=${primary.length} secondary=${secondary.length} final=${all.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return all.values.toList();
  }

  Future<List<OptionModel>> listarMarcas({String status = ''}) {
    if (kDebugMode) debugPrint('[COMBOS-REPO] listarMarcas status="$status"');
    return _fetchOptions('/app-marcas', status: status);
  }

  Future<List<OptionModel>> listarCondicoesEmbalagem({String status = ''}) {
    if (kDebugMode) debugPrint('[COMBOS-REPO] listarCondicoesEmbalagem status="$status"');
    return _fetchOptions('/app-embalagens-condicoes', status: status);
  }

  Future<OptionModel?> carregarPessoaPorId(int id) async {
    final t0 = DateTime.now();
    if (kDebugMode) debugPrint('[COMBOS-REPO] carregarPessoaPorId id=$id');
    try {
      final resp =
          await service.dio.get('/fornecedores-fabricantes-edit/$id');
      if (resp.statusCode == 200 &&
          resp.data is Map &&
          resp.data['success'] == true) {
        final data = resp.data['data'];
        if (data is Map) {
          return OptionModel.fromJson({
            'id_pessoas': data['id_pessoas'],
            'descricao': data['nm_pessoa'] ?? data['nome'],
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('carregarPessoaPorId erro: $e');
    }
    if (kDebugMode) debugPrint('[COMBOS-REPO] carregarPessoaPorId id=$id NOTFOUND dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return null;
  }

  Future<Map<String, dynamic>?> carregarPessoaDetalhes(int id) async {
    final t0 = DateTime.now();
    if (kDebugMode) debugPrint('[COMBOS-REPO] carregarPessoaDetalhes id=$id');
    try {
      final resp =
          await service.dio.get('/fornecedores-fabricantes-edit/$id');
      if (resp.statusCode == 200 &&
          resp.data is Map &&
          resp.data['success'] == true) {
        final data = resp.data['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('carregarPessoaDetalhes erro: $e');
    }
    if (kDebugMode) debugPrint('[COMBOS-REPO] carregarPessoaDetalhes id=$id NOTFOUND dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return null;
  }

  Future<List<OptionModel>> _fetchOptions(
    String endpoint, {
    String status = 'A',
    Map<String, dynamic>? query,
  }) async {
    final t0 = DateTime.now();
    final connected = await _network.checkNetworkAcess();
    if (!connected) return <OptionModel>[];

    final queryParameters = {
      'status': status,
      if (query != null) ...query,
    };

    // Verifica cache antes de requisição
    final cacheKey = _buildKey(endpoint, queryParameters);
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    if (cached != null && now.difference(cached.timestamp) < _ttl) {
      if (kDebugMode) debugPrint('CombosRepository CACHE HIT: $cacheKey');
      return cached.data;
    }

    try {
      final resp =
          await service.dio.get(endpoint, queryParameters: queryParameters);
      if (resp.statusCode == 200) {
        final data = resp.data is Map ? resp.data['data'] ?? resp.data : resp.data;
        if (data is List) {
          final list = data
              .whereType<Map>()
              .map((e) => OptionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _cache[cacheKey] = _ComboCacheEntry(list, now);
          if (kDebugMode) debugPrint('[COMBOS-REPO] $endpoint fetched list=${list.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms status="$status" query=${queryParameters}');
          return list;
        }
        if (data is Map) {
          final list = data.values
              .whereType<Map>()
              .map((e) => OptionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _cache[cacheKey] = _ComboCacheEntry(list, now);
          if (kDebugMode) debugPrint('[COMBOS-REPO] $endpoint fetched map->list=${list.length} dur=${DateTime.now().difference(t0).inMilliseconds}ms status="$status" query=${queryParameters}');
          return list;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CombosRepository $endpoint erro: $e');
    }
    if (kDebugMode) debugPrint('[COMBOS-REPO] $endpoint vazio dur=${DateTime.now().difference(t0).inMilliseconds}ms status="$status" query=${queryParameters}');
    return <OptionModel>[];
  }
}

class _ComboCacheEntry {
  final List<OptionModel> data;
  final DateTime timestamp;
  _ComboCacheEntry(this.data, this.timestamp);
}
