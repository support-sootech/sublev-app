import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ootech/repositories/materiais_repository.dart';
import 'package:ootech/views/entrada_materiais_page.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class MateriaisListPage extends StatefulWidget {
  const MateriaisListPage({super.key});

  @override
  State<MateriaisListPage> createState() => _MateriaisListPageState();
}

class _MateriaisListPageState extends State<MateriaisListPage> {
  final MateriaisRepository _repo = MateriaisRepository();
  bool _loading = true;
  final List<Map<String, dynamic>> _allItems = [];
  final List<Map<String, dynamic>> _filteredItems = [];
  final List<Map<String, dynamic>> _visibleItems = [];
  static const int _pageSize = 30;
  bool _loadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFiltro = '';
  String _searchTerm = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final materiais = await _repo.listar(status: _statusFiltro);
      _allItems
        ..clear()
        ..addAll(materiais.map((m) => m.toJson()));
      _applyFilters();
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar materiais: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao carregar materiais: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final term = _searchTerm.trim().toLowerCase();
    final base = term.isEmpty
        ? List<Map<String, dynamic>>.from(_allItems)
        : _allItems.where((item) {
            bool matches(dynamic value) =>
                value != null &&
                value.toString().toLowerCase().contains(term);
            return matches(item['descricao']) ||
                matches(item['cod_barras']) ||
                matches(item['marca']) ||
                matches(item['nm_fornecedor']) ||
                matches(item['nm_fabricante']) ||
                matches(item['lote']);
          }).toList();
    _filteredItems
      ..clear()
      ..addAll(base);
      _visibleItems
        ..clear()
        ..addAll(_filteredItems.take(_pageSize));
    _hasMore = _visibleItems.length < _filteredItems.length;
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 150));
    final current = _visibleItems.length;
    final nextSlice = _filteredItems.skip(current).take(_pageSize).toList();
    _visibleItems.addAll(nextSlice);
    _hasMore = _visibleItems.length < _filteredItems.length;
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _refresh() async {
    await _load();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _searchTerm = _searchCtrl.text;
      _applyFilters();
    });
  }

  void _setStatusFiltro(String value) {
    if (_statusFiltro == value) return;
    setState(() => _statusFiltro = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrada de Materiais', style: TextStyle(fontSize: 20)),
          flexibleSpace: AppBarLinearGradientWidget(),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'Filtrar status',
              onSelected: _setStatusFiltro,
              itemBuilder: (context) => const [
                PopupMenuItem(value: '', child: Text('Todos')),
                PopupMenuItem(value: 'A', child: Text('Ativos')),
                PopupMenuItem(value: 'D', child: Text('Inativos')),
              ],
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _visibleItems.isEmpty
                ? Column(
                    children: [
                      _buildSearchBar(context),
                      const Expanded(
                        child: Center(child: Text('Nenhum material encontrado')),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _visibleItems.length + (_hasMore ? 2 : 1),
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          return _buildSearchBar(context);
                        }
                        final dataIndex = idx - 1;
                        if (dataIndex >= _visibleItems.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: _loadingMore
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Carregar mais...'),
                            ),
                          );
                        }
                        final it = _visibleItems[dataIndex];
                        final id = it['id_materiais'] ?? it['id'] ?? 0;
                        final descricao = (it['descricao'] ?? '').toString();
                        final cod = (it['cod_barras'] ?? '').toString();
                        final quantidade = (it['quantidade'] ?? '').toString();
                        final estoqueLabel = quantidade.isEmpty ? '—' : quantidade;
                        final marca = (it['marca'] ?? '').toString();
                        final marcaLabel = marca.isEmpty ? '—' : marca;
                        final fornecedor = (it['nm_fornecedor'] ?? '').toString();
                        final fabricante = (it['nm_fabricante'] ?? '').toString();
                        final fornecedorLabel = fornecedor.isEmpty ? '—' : fornecedor;
                        final fabricanteLabel = fabricante.isEmpty ? '—' : fabricante;
                        final status = (it['status'] ?? '').toString();
                        final statusLabel = status.isEmpty ? '—' : status;

                        Color statusColor;
                        switch (status) {
                          case 'A':
                            statusColor = Colors.green.shade600;
                            break;
                          case 'D':
                            statusColor = Colors.red.shade600;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        descricao,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => EntradaMateriaisPage(
                                                    materialId: int.tryParse(id.toString())),
                                              ),
                                            );
                                            _refresh();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Excluir',
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _confirmDelete(id, descricao),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Código de Barras: ${cod.isEmpty ? '—' : cod}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qtd. Estoque: $estoqueLabel',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text('Marca: $marcaLabel', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Fabricante: $fabricanteLabel', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Fornecedor: $fornecedorLabel', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(.4)),
                                    ),
                                    child: Text(
                                      statusLabel == 'A'
                                          ? 'Ativo'
                                          : (statusLabel == 'D' ? 'Inativo' : statusLabel),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EntradaMateriaisPage()));
            await _refresh();
          },
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          labelText: 'Filtrar por código, descrição, marca...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchTerm = '';
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmDelete(int id, String descricao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o material "$descricao"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final sucesso = await _repo.deletar(id);
      if (sucesso) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Material excluído')));
        }
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }
}
