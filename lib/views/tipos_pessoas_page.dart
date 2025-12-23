import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/tipo_pessoa_model.dart';
import 'package:ootech/repositories/tipo_pessoa_repository.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class TiposPessoasPage extends StatefulWidget {
  const TiposPessoasPage({super.key});

  @override
  State<TiposPessoasPage> createState() => _TiposPessoasPageState();
}

class _TiposPessoasPageState extends State<TiposPessoasPage> {
  final TipoPessoaRepository _repo = TipoPessoaRepository();
  bool _loading = true;
  final List<TipoPessoaModel> _allItems = [];
  final List<TipoPessoaModel> _filteredItems = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFiltro = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.listar();
      _allItems
        ..clear()
        ..addAll(items);
      _applyFilters();
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar tipos pessoas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters({bool triggerSetState = false}) {
    final term = _searchCtrl.text.trim().toLowerCase();
    final base = _allItems.where((item) {
      // Filtro por status
      if (_statusFiltro.isNotEmpty && item.status != _statusFiltro) {
        return false;
      }
      // Filtro por termo de busca
      if (term.isNotEmpty) {
        return item.descricao?.toLowerCase().contains(term) ?? false;
      }
      return true;
    }).toList();
    _filteredItems
      ..clear()
      ..addAll(base);
    if (triggerSetState && mounted) setState(() {});
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _applyFilters(triggerSetState: true);
    });
  }

  void _setStatusFiltro(String value) {
    if (_statusFiltro == value) return;
    setState(() => _statusFiltro = value);
    _applyFilters(triggerSetState: true);
  }

  Future<void> _refresh() async {
    await _load();
  }

  void _showFormDialog({TipoPessoaModel? tipoPessoa}) {
    final isEditing = tipoPessoa != null;
    final descricaoCtrl = TextEditingController(text: tipoPessoa?.descricao ?? '');
    String status = tipoPessoa?.status ?? 'A';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Tipo Pessoa' : 'Novo Tipo Pessoa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descricaoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('Ativo')),
                    DropdownMenuItem(value: 'I', child: Text('Inativo')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => status = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final descricao = descricaoCtrl.text.trim();
                if (descricao.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Descrição é obrigatória')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _salvar(
                  TipoPessoaModel(
                    id: tipoPessoa?.id,
                    descricao: descricao,
                    status: status,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar(TipoPessoaModel tipoPessoa) async {
    try {
      final sucesso = await _repo.salvar(tipoPessoa);
      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tipoPessoa.id != null ? 'Atualizado com sucesso!' : 'Cadastrado com sucesso!'),
          ),
        );
        await _refresh();
      }
    } on CustomException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  void _confirmDelete(TipoPessoaModel tipoPessoa) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir "${tipoPessoa.descricao}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || tipoPessoa.id == null) return;
    try {
      final sucesso = await _repo.deletar(tipoPessoa.id!);
      if (sucesso && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
        await _refresh();
      }
    } on CustomException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tipos de Pessoas', style: TextStyle(fontSize: 20)),
          flexibleSpace: AppBarLinearGradientWidget(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'Filtrar status',
              onSelected: _setStatusFiltro,
              itemBuilder: (context) => const [
                PopupMenuItem(value: '', child: Text('Todos')),
                PopupMenuItem(value: 'A', child: Text('Ativos')),
                PopupMenuItem(value: 'I', child: Text('Inativos')),
              ],
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filteredItems.isEmpty
                ? Column(
                    children: [
                      _buildSearchBar(),
                      const Expanded(
                        child: Center(child: Text('Nenhum tipo de pessoa encontrado')),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredItems.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == 0) return _buildSearchBar();
                        final item = _filteredItems[idx - 1];
                        return _buildCard(item);
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showFormDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          labelText: 'Filtrar por descrição...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilters(triggerSetState: true);
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCard(TipoPessoaModel item) {
    final statusLabel = item.status == 'A' ? 'Ativo' : (item.status == 'I' ? 'Inativo' : item.status ?? '—');
    final statusColor = item.status == 'A' ? Colors.green.shade600 : Colors.red.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.descricao ?? '—',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showFormDialog(tipoPessoa: item),
            ),
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(item),
            ),
          ],
        ),
      ),
    );
  }
}
