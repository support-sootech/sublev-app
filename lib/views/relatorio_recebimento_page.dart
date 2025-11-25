import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ootech/controller/relatorio_recebimento_controller.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:open_filex/open_filex.dart';

class RelatorioRecebimentoPage extends StatefulWidget {
  const RelatorioRecebimentoPage({super.key});

  @override
  State<RelatorioRecebimentoPage> createState() => _RelatorioRecebimentoPageState();
}

class _RelatorioRecebimentoPageState extends State<RelatorioRecebimentoPage> {
  final RelatorioRecebimentoController ctrl = Get.put(RelatorioRecebimentoController());
  final UserSharedPreferencesRepository _userRepo = UserSharedPreferencesRepository();
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late DateTime _dtIni = ctrl.dtIni.value;
  late DateTime _dtFim = ctrl.dtFim.value;
  late Worker _itemsWorker;
  List<RelatorioRecebimentoItem> _allItems = [];
  List<RelatorioRecebimentoItem> _filteredItems = [];
  List<RelatorioRecebimentoItem> _visibleItems = [];
  static const int _pageSize = 20;
  bool _loadingMore = false;
  bool _hasMore = false;
  String _searchTerm = '';
  String? _userName;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _itemsWorker = ever<List<RelatorioRecebimentoItem>>(ctrl.itens, (_) {
      setState(() {
        _allItems = ctrl.itens.toList();
        _applyFilters();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _aplicarFiltros();
    });
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final logged = await UserSharedPreferencesRepository.isLogged();
    if (!logged) return;
    try {
      final UserModel user = await _userRepo.getUserSharedPreferences();
      if (!mounted) return;
      setState(() => _userName = user.nmPessoa);
    } catch (_) {
      if (!mounted) return;
      setState(() => _userName = null);
    }
  }

  void _applyFilters() {
    final termRaw = _searchCtrl.text;
    _searchTerm = termRaw;
    final term = termRaw.trim().toLowerCase();
    _filteredItems = term.isEmpty
        ? List.from(_allItems)
        : _allItems.where((item) => _matchesSearch(item, term)).toList();
    _visibleItems = _filteredItems.take(_pageSize).toList();
    _hasMore = _visibleItems.length < _filteredItems.length;
    _loadingMore = false;
  }

  bool _matchesSearch(RelatorioRecebimentoItem item, String term) {
    bool contains(String? value) => (value ?? '').toLowerCase().contains(term);
    return contains(item.descricao) ||
        contains(item.nmFornecedor) ||
        contains(item.lote) ||
        contains(item.nroNota) ||
        contains(item.nmResponsavel);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(_applyFilters);
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      final current = _visibleItems.length;
      final nextSlice = _filteredItems.skip(current).take(_pageSize).toList();
      setState(() {
        _visibleItems.addAll(nextSlice);
        _hasMore = _visibleItems.length < _filteredItems.length;
        _loadingMore = false;
      });
    });
  }

  Future<void> _selecionarData(BuildContext context, {required bool inicio}) async {
    final initialDate = inicio ? _dtIni : _dtFim;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (inicio) {
          _dtIni = picked;
          if (_dtIni.isAfter(_dtFim)) _dtFim = _dtIni;
        } else {
          _dtFim = picked;
          if (_dtFim.isBefore(_dtIni)) _dtIni = _dtFim;
        }
      });
    }
  }

  void _aplicarFiltros() {
    if (_dtIni.isAfter(_dtFim)) {
      _mostrarSnack('Data inicial não pode ser maior que a final.');
      return;
    }
    ctrl.aplicarFiltros(
      _dtIni,
      _dtFim,
      filtroBusca: _searchCtrl.text.trim(),
    );
  }

  Future<void> _exportarPdf() async {
    final File? arquivo = await ctrl.gerarPdf(
      filtroBusca: _searchCtrl.text.trim(),
    );
    if (arquivo == null) {
      final msg = ctrl.exportErro.value ?? 'Não foi possível gerar o PDF.';
      _mostrarSnack(msg, isError: true);
      return;
    }
    await OpenFilex.open(arquivo.path);
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _itemsWorker.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatório de Recebimento',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20),
        ),
        flexibleSpace: AppBarLinearGradientWidget(),
      ),
      body: Column(
        children: [
          _buildFiltros(context),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (ctrl.carregando.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.erro.value != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      ctrl.erro.value!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (_visibleItems.isEmpty) {
                return const Center(child: Text('Nenhum registro no período.'));
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ctrl.carregar(refresh: true, filtroBusca: ctrl.filtroTexto.value),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: _visibleItems.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _visibleItems.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Carregando mais...'),
                        ),
                      );
                    }
                    final item = _visibleItems[index];
                    return _ItemWidget(item: item);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_userName != null) ...[
              const SizedBox(height: 2),
              Text('Usuário: $_userName', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Data início',
                    value: _fmt.format(_dtIni),
                    onTap: () => _selecionarData(context, inicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateSelector(
                    label: 'Data final',
                    value: _fmt.format(_dtFim),
                    onTap: () => _selecionarData(context, inicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar por descrição, fornecedor, lote ou nota',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _onSearchChanged(),
              onSubmitted: (_) => _aplicarFiltros(),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final exportando = ctrl.exportando.value;
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.carregando.value ? null : _aplicarFiltros,
                      icon: const Icon(Icons.search),
                      label: const Text('Filtrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: exportando ? null : _exportarPdf,
                      icon: exportando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateSelector({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final RelatorioRecebimentoItem item;
  const _ItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.descricao ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info('Cadastro', item.dhCadastro),
                _info('Validade', item.dtVencimento),
                _info('Quantidade', item.quantidade ?? '0'),
                _info('Fornecedor', item.nmFornecedor),
                _info('Temperatura', item.temperatura != null && item.temperatura!.isNotEmpty ? '${item.temperatura}ºC' : null),
                _info('SIF', item.sif),
                _info('Lote', item.lote),
                _info('Nota', item.nroNota),
                _info('Condição', item.dsEmbalagemCondicoes),
                _info('Responsável', item.nmResponsavel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String? value, {bool highlight = false}) {
    final raw = value?.trim() ?? '';
    final display = raw.isEmpty ? '—' : raw;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(display, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
