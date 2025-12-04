import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:ootech/controller/entrada_materiais_controller.dart';
import 'package:ootech/repositories/entrada_materiais_repository.dart';
import 'package:ootech/repositories/produto_repository.dart';
import 'package:ootech/models/produto_model.dart';
import 'package:ootech/services/network_access.dart';
import 'package:ootech/models/option_model.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:ootech/views/widgets/barcode_scanner_dialog.dart';
import 'package:ootech/views/widgets/dropdown_option_reactive.dart';

class EntradaMateriaisPage extends StatefulWidget {
  /// Se [materialId] for fornecido, a tela abre em modo de edição carregando
  /// os dados do backend e permitindo atualizar a entrada existente.
  final int? materialId;
  const EntradaMateriaisPage({super.key, this.materialId});

  @override
  State<EntradaMateriaisPage> createState() => _EntradaMateriaisPageState();
}

class _EntradaMateriaisPageState extends State<EntradaMateriaisPage> {
  final _formKey = GlobalKey<FormState>();
  late final EntradaMateriaisController _ctrl;

  final _nomeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _codBarrasCtrl = TextEditingController();
  final _diasVencCtrl = TextEditingController();
  final _diasVencAbertoCtrl = TextEditingController();
  DateTime? _fabricacao;
  final _quantidadeCtrl = TextEditingController(text: '1');
  final _loteCtrl = TextEditingController();
  final _nroNotaCtrl = TextEditingController();
  final _temperaturaCtrl = TextEditingController();
  final _sifCtrl = TextEditingController();
  final Rx<String> _statusSel = Rx<String>('A');
  DateTime? _validade;

  bool _loading = true;
  bool _saving = false;
  final Map<String, String?> _serverErrors = {};

  // Autocomplete produtos
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  List<ProdutoModel> _produtoSugestoes = [];
  bool _loadingSugestoes = false;
  String? _erroSugestoes;
  DateTime? _lastQueryTime;
  static const Duration _debounceDur = Duration(milliseconds: 320);
  final _networkAccess = NetworkAccess();
  bool _produtoSelecionado = false; // evita exibir mensagem fixa após selecionar
  bool _descAvisoTruncadoMostrado = false; // evita spam de snackbar ao truncar digitação
  Future<void> _buscarSugestoes(String termo) async {
    final agora = DateTime.now();
    _lastQueryTime = agora;
    await Future.delayed(_debounceDur);
    if (_lastQueryTime != agora) return; // houve nova digitação
    if (!mounted) return;
    setState(() { _loadingSugestoes = true; _erroSugestoes = null; });
    // Verifica conectividade antes de chamar backend
    final online = await _networkAccess.checkNetworkAcess();
    if (!online) {
      if (!mounted) return;
      setState(() {
        _loadingSugestoes = false;
        _erroSugestoes = 'Sem conexão. Sugestões indisponíveis.';
        _produtoSugestoes = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: não foi possível buscar produtos')));
      return;
    }
    try {
      final lista = await _produtoRepo.autocompleteProdutos(termo);
      if (!mounted) return;
      setState(() { _produtoSugestoes = lista; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _erroSugestoes = 'Falha ao buscar sugestões'; });
    } finally {
      if (mounted) setState(() { _loadingSugestoes = false; });
    }
  }
  void _onDescricaoChanged(String v) {
    // Assim que o usuário altera o texto, considere que não há produto aplicado
    if (_produtoSelecionado) setState(() => _produtoSelecionado = false);

    // Enforcar limite de 100 caracteres ainda na digitação para evitar erro no backend
    final txt = v;
    if (txt.length > 100) {
      final caret = _nomeCtrl.selection.baseOffset;
      _nomeCtrl.text = txt.substring(0, 100);
      final newPos = caret.clamp(0, 100);
      _nomeCtrl.selection = TextSelection.collapsed(offset: newPos);
      if (!_descAvisoTruncadoMostrado && mounted) {
        _descAvisoTruncadoMostrado = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descrição limitada a 100 caracteres.')),
        );
      }
    }
    if (v.trim().length < 2) {
      if (_produtoSugestoes.isNotEmpty) setState(() => _produtoSugestoes = []);
      return;
    }
    _buscarSugestoes(v);
  }
  void _aplicarProduto(ProdutoModel p) async {
    // Preservar seleção de fabricante/fornecedor em modo edição: alguns fluxos
    // anteriores limpavam estas seleções; aqui garantimos que permanecem.
    final fabricanteAnterior = _ctrl.fabricanteSel.value;
    final fornecedorAnterior = _ctrl.fornecedorSel.value;
    _nomeCtrl.text = p.descricao;
    if (widget.materialId != null) {
      _codBarrasCtrl.text = p.codigoBarras; // em edição, sempre atualizar código de barras
    } else {
      if (_codBarrasCtrl.text.trim().isEmpty) _codBarrasCtrl.text = p.codigoBarras;
    }
    _serverErrors.remove('id_pessoas_fabricante');
    _serverErrors.remove('fabricante');
    _serverErrors.remove('id_pessoas_fornecedor');
    _serverErrors.remove('fornecedor');
    // Buscar detalhes para preencher dias/peso/unidade/modo conservação
    _preencherDetalhesProduto(p.codigoBarras);
    setState(() {
      _produtoSugestoes = [];
      _produtoSelecionado = true;
      // Reaplicar seleções anteriores se o controller tiver sido alterado por algum efeito colateral
      if (widget.materialId != null) {
        if (fabricanteAnterior != null && _ctrl.fabricanteSel.value == null) {
          _ctrl.fabricanteSel.value = fabricanteAnterior;
        }
        if (fornecedorAnterior != null && _ctrl.fornecedorSel.value == null) {
          _ctrl.fornecedorSel.value = fornecedorAnterior;
        }
      }
    });
  }

  Future<void> _preencherDetalhesProduto(String codigo) async {
    try {
      final detalhes = await _produtoRepo.buscarPorCodigoBarras(codigo);
      if (detalhes == null) return;
      // Preencher dias de vencimento se campos vazios e dados disponíveis
      if (_diasVencCtrl.text.trim().isEmpty && detalhes.diasVencimento != null) {
        _diasVencCtrl.text = detalhes.diasVencimento.toString();
      }
      if (_diasVencAbertoCtrl.text.trim().isEmpty && detalhes.diasVencimentoAberto != null) {
        _diasVencAbertoCtrl.text = detalhes.diasVencimentoAberto.toString();
      }
      if (_pesoCtrl.text.trim().isEmpty && detalhes.peso != null) {
        _pesoCtrl.text = detalhes.peso.toString();
      }
      // Selecionar unidade de medida se disponível
      if (detalhes.idUnidadesMedidas != null && _ctrl.unidadeSel.value == null) {
        _selectById(_ctrl.unidades, _ctrl.unidadeSel, detalhes.idUnidadesMedidas);
      }
      // Selecionar modo de conservação
      if (detalhes.idModoConservacao != null && _ctrl.modoConservacaoSel.value == null) {
        _selectById(_ctrl.modosConservacao, _ctrl.modoConservacaoSel, detalhes.idModoConservacao);
      }
      // Calcular validade automática se fabricação + dias vencimento disponíveis
      if (_fabricacao != null && _validade == null && detalhes.diasVencimento != null) {
        setState(() { _validade = _fabricacao!.add(Duration(days: detalhes.diasVencimento!)); });
      } else {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Evita múltiplos Get.put gerando conflito ou "improper use" quando a mesma rota é aberta várias vezes.
    // Usa instância já registrada via lazyPut em main (fenix true) para evitar múltiplos Get.put.
    _ctrl = Get.find<EntradaMateriaisController>();
    if (kDebugMode) debugPrint('[EntradaMateriaisPage] initState controllerHash=${identityHashCode(_ctrl)} pageHash=${identityHashCode(this)}');
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.materialId != null) {
      // Modo edição: bloquear até combos + registro completamente carregados.
      setState(() => _loading = true);
      if (kDebugMode) debugPrint('[EntradaMateriaisPage] Bootstrap edição: iniciando carga completa combos+registro');
      try {
        await _ctrl.forceReloadCombos();
        await _loadExisting(widget.materialId!);
        if (kDebugMode) debugPrint('[EntradaMateriaisPage] Bootstrap edição concluído (tudo carregado)');
      } catch (e) {
        if (kDebugMode) debugPrint('[EntradaMateriaisPage] Erro bootstrap edição: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Inclusão: bloquear até TODOS os combos estarem disponíveis, garantindo
      // que fornecedor/fabricante/marca/etc. já tenham carregado antes de abrir a tela.
      setState(() => _loading = true);
      if (kDebugMode) debugPrint('[EntradaMateriaisPage] Bootstrap inclusão: aguardando carga completa de combos...');
      try {
        // Limpar seleções iniciais
        _ctrl.categoriaSel.value = null;
        _ctrl.fornecedorSel.value = null;
        _ctrl.fabricanteSel.value = null;
        _ctrl.marcaSel.value = null;
        _ctrl.condicaoEmbalagemSel.value = null;
        _ctrl.unidadeSel.value = null;
        _ctrl.modoConservacaoSel.value = null;
        await _ctrl.forceReloadCombos();
        // Seleciona unidade padrão 'kg' quando disponível após carga.
        try {
          final kg = _ctrl.unidades.firstWhere(
            (u) => (u.descricao.trim().toLowerCase() == 'kg' || u.descricao.trim().toLowerCase() == 'kg.'),
            orElse: () => OptionModel(id: 0, descricao: ''),
          );
          if (kg.id != 0 && _ctrl.unidadeSel.value == null) {
            _ctrl.unidadeSel.value = kg;
          }
        } catch (_) {}
        if (kDebugMode) debugPrint('[EntradaMateriaisPage] Bootstrap inclusão concluído (combos completos prontos)');
      } catch (e) {
        if (kDebugMode) debugPrint('[EntradaMateriaisPage] Erro bootstrap inclusão: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadExisting(int id) async {
    try {
      final resp = await _repo.loadById(id);
      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'] as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('[EDIT] Raw data id=$id -> ${data.keys.toList()}');
          debugPrint('[EDIT] Valores principais: condicao=${data['id_embalagem_condicoes']} sif=${data['sif']} temp=${data['temperatura']} nota=${data['nro_nota']}');
        }
        // Preencher campos simples
        _nomeCtrl.text = (data['descricao'] ?? '') as String;
        _pesoCtrl.text = (data['peso'] != null) ? data['peso'].toString() : _pesoCtrl.text;
        _codBarrasCtrl.text = (data['cod_barras'] ?? '') as String;
        _quantidadeCtrl.text = (data['quantidade'] ?? _quantidadeCtrl.text).toString();
        _loteCtrl.text = (data['lote'] ?? '') as String;

        // Dias de vencimento e outros campos numéricos/texto
        _diasVencCtrl.text = (data['dias_vencimento'] != null) ? data['dias_vencimento'].toString() : '';
        _diasVencAbertoCtrl.text = (data['dias_vencimento_aberto'] != null) ? data['dias_vencimento_aberto'].toString() : '';
        _nroNotaCtrl.text = (data['nro_nota'] ?? '') as String;
        // Alguns registros podem usar chaves alternativas (ex: 'temp' ou 'sif_registro'). Realiza fallback heurístico.
        final tempVal = data['temperatura'] ?? data['temp'] ?? data['temp_armazenamento'];
        final sifVal = data['sif'] ?? data['sif_registro'] ?? data['registro_sif'];
        final notaVal = data['nro_nota'] ?? data['nota_fiscal'] ?? data['nf'];
        _temperaturaCtrl.text = tempVal != null ? tempVal.toString() : '';
        _sifCtrl.text = sifVal != null ? sifVal.toString() : '';
        _nroNotaCtrl.text = notaVal != null ? notaVal.toString() : _nroNotaCtrl.text;

        // Validade: esperar formato dd/MM/yyyy do servidor
        if (data['dt_vencimento'] != null && (data['dt_vencimento'] as String).isNotEmpty) {
          try {
            final parts = (data['dt_vencimento'] as String).split('/');
            if (parts.length == 3) {
              final d = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              final y = int.parse(parts[2]);
              _validade = DateTime(y, m, d);
            }
          } catch (_) {}
        }

        // Data de fabricação
        if (data['dt_fabricacao'] != null && (data['dt_fabricacao'] as String).isNotEmpty) {
          try {
            final parts = (data['dt_fabricacao'] as String).split('/');
            if (parts.length == 3) {
              final d = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              final y = int.parse(parts[2]);
              _fabricacao = DateTime(y, m, d);
            }
          } catch (_) {}
        }

        // Selecionar opções nos dropdowns buscando pelo id retornado
  _selectById(_ctrl.categorias, _ctrl.categoriaSel, data['id_materiais_categorias']);
  _selectById(_ctrl.fornecedores, _ctrl.fornecedorSel, data['id_pessoas_fornecedor'] ?? data['id_pessoas']);
  _selectById(_ctrl.fabricantes, _ctrl.fabricanteSel, data['id_pessoas_fabricante'] ?? data['id_pessoas']);
  _selectById(_ctrl.marcas, _ctrl.marcaSel, data['id_materiais_marcas']);
  // Condição de embalagem: se id ausente tentar heurísticas ('id_embalagem_condicao', 'embalagem_condicao_id')
  _selectById(_ctrl.condicoesEmbalagem, _ctrl.condicaoEmbalagemSel,
    data['id_embalagem_condicoes'] ?? data['id_embalagem_condicao'] ?? data['embalagem_condicoes_id'] ?? data['embalagem_condicao_id'] ?? data['id']);
  _selectById(_ctrl.unidades, _ctrl.unidadeSel, data['id_unidades_medidas'] ?? data['id_unidades_medida']);
  _selectById(_ctrl.modosConservacao, _ctrl.modoConservacaoSel, data['id_modo_conservacao'] ?? data['id']);

        // Caso o item selecionado (fornecedor/fabricante) não exista nas listas atuais,
        // buscar diretamente pelo ID (padrão da web) e injetar para permitir a pré-seleção.
        await _ensurePessoaInList(
          list: _ctrl.fornecedores,
          sel: _ctrl.fornecedorSel,
          id: data['id_pessoas_fornecedor'],
        );
        await _ensurePessoaInList(
          list: _ctrl.fabricantes,
          sel: _ctrl.fabricanteSel,
          id: data['id_pessoas_fabricante'],
        );

        // Paridade web adicional: se não houver fabricante associado (id_pessoas_fabricante null)
        // mas existir marca selecionada, tentar auto-relacionar pelo nome exato (case-insensitive).
        // Web costuma exibir fabricante quando já há correlação por cadastro; aqui replicamos heurística.
        if (_ctrl.fabricanteSel.value == null && _ctrl.marcaSel.value != null) {
          final nomeMarca = _ctrl.marcaSel.value!.descricao.trim().toLowerCase();
          final possivel = _ctrl.fabricantes.firstWhere(
            (f) => f.descricao.trim().toLowerCase() == nomeMarca,
            orElse: () => OptionModel(id: 0, descricao: ''),
          );
          if (possivel.id != 0) {
            _ctrl.fabricanteSel.value = possivel;
          }
        }

        // Status (A/D)
        if (data['status'] != null) {
          try {
            _statusSel.value = data['status'] as String;
          } catch (_) {}
        }
      } else {
        final msg = resp['msg'] ?? 'Não foi possível carregar o registro para edição';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar material $id: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar material: $e')));
    }
  }

  Future<void> _ensurePessoaInList({required List<OptionModel> list, required Rx<OptionModel?> sel, dynamic id}) async {
    if (id == null) return;
    final idStr = id.toString();
    final exists = list.any((e) => e.id.toString() == idStr);
    if (exists) {
      // Já existe; apenas selecionar se ainda não selecionado
      if (sel.value == null || sel.value!.id.toString() != idStr) {
        _selectById(list, sel, id);
      }
      return;
    }
    final opt = await _ctrl.combosRepository
        .carregarPessoaPorId(int.tryParse(idStr) ?? 0);
    if (opt != null) {
      list.add(opt);
      _selectById(list, sel, id);
      if (mounted) setState(() {});
    }
  }

  void _selectById(List<OptionModel> list, Rx<OptionModel?> sel, dynamic id) {
    // Quando o id não foi informado ou o item não existir na lista atual, limpe a seleção
    if (id == null) {
      sel.value = null;
      return;
    }
    OptionModel? found;
    for (final it in list) {
      if (it.id.toString() == id.toString()) {
        found = it;
        break;
      }
    }
    sel.value = found; // pode ser null se não encontrou
  }

  Future<void> _scanCodigoBarras() async {
    if (widget.materialId != null) return;
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const BarcodeScannerDialog(),
    );
    if (code == null || code.trim().isEmpty) return;
    _serverErrors.remove('cod_barras');
    setState(() => _codBarrasCtrl.text = code.trim());
    final online = await _networkAccess.checkNetworkAcess();
    if (!online) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código lido, mas sem conexão para buscar o produto.'),
        ),
      );
      return;
    }
    try {
      final prod = await _produtoRepo.buscarPorCodigoBarras(code.trim());
      if (prod != null) {
        if (!mounted) return;
        _aplicarProduto(prod);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto carregado pelo código de barras.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código registrado. Preencha os demais dados.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao buscar detalhes: $e')),
      );
    }
  }

  @override
  void dispose() {
    if (kDebugMode) debugPrint('[EntradaMateriaisPage] dispose controllerHash=${identityHashCode(_ctrl)} pageHash=${identityHashCode(this)}');
    _nomeCtrl.dispose();
    _pesoCtrl.dispose();
    _codBarrasCtrl.dispose();
    _diasVencCtrl.dispose();
    _diasVencAbertoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _loteCtrl.dispose();
    _nroNotaCtrl.dispose();
    _temperaturaCtrl.dispose();
    _sifCtrl.dispose();
    // Não remove controller (gerenciado globalmente pelo Get, fenix=true).
    super.dispose();
  }

  final EntradaMateriaisRepository _repo = EntradaMateriaisRepository();

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      // limpar erros anteriores
      _serverErrors.clear();
      // Truncar descrição para no máximo 100 caracteres no envio
      String desc = _nomeCtrl.text.trim();
      bool descTruncada = false;
      if (desc.length > 100) {
        desc = desc.substring(0, 100);
        descTruncada = true;
        // Informar de forma não bloqueante
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descrição excede 100 caracteres e será truncada ao salvar.')));
      }

      final df = DateFormat('dd/MM/yyyy');
      // Build payload with server-expected keys prefixed by 'material_'
      // Converte entrada livre para formato brasileiro de peso (vírgula decimal, sem milhar)
      String _formatPesoBR(String s) => s.trim();
      String _normalizeInt(String s) {
        var t = s.trim();
        if (t.isEmpty) return '';
        // Mantém somente dígitos (remove pontuação, vírgulas, espaços)
        t = t.replaceAll(RegExp(r'[^0-9]'), '');
        return t;
      }

      final codBarras = _codBarrasCtrl.text.trim();

      final data = {
        'material_descricao': desc,
        'material_quantidade': _normalizeInt(_quantidadeCtrl.text),
        'material_lote': _loteCtrl.text.trim(),
        'material_dt_vencimento': _validade == null ? '' : df.format(_validade!),
        'material_dt_fabricacao': _fabricacao == null ? '' : df.format(_fabricacao!),
        'material_dias_vencimento': _diasVencCtrl.text.trim(),
        'material_dias_vencimento_aberto': _diasVencAbertoCtrl.text.trim(),
        'material_id_unidades_medidas': _ctrl.unidadeSel.value?.id,
        'material_id_materiais_categorias': _ctrl.categoriaSel.value?.id,
        'material_id_materiais_marcas': _ctrl.marcaSel.value?.id,
        'material_id_embalagem_condicoes': _ctrl.condicaoEmbalagemSel.value?.id,
        'material_id_modo_conservacao': _ctrl.modoConservacaoSel.value?.id,
        'material_peso': _formatPesoBR(_pesoCtrl.text),
        'material_cod_barras': codBarras.isEmpty ? null : codBarras,
        'material_nro_nota': _nroNotaCtrl.text.trim(),
        'material_temperatura': _temperaturaCtrl.text.trim(),
        'material_sif': _sifCtrl.text.trim(),
        'material_status': _statusSel.value,
      };
      if (kDebugMode) debugPrint('[ENTRADA][PAYLOAD] $data');

      // Adicionar fornecedor/fabricante somente se selecionados (evita enviar null e acionar validação indevida)
      final fabricanteId = _ctrl.fabricanteSel.value?.id;
      if (fabricanteId != null) {
        data['material_id_pessoas_fabricante'] = fabricanteId;
      }
      final fornecedorId = _ctrl.fornecedorSel.value?.id;
      if (fornecedorId != null) {
        data['material_id_pessoas_fornecedor'] = fornecedorId;
      }

      // Pré-validação local: garante que fabricante ainda existe na lista carregada.
      if (fabricanteId != null && !_ctrl.fabricantes.any((f) => f.id == fabricanteId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fabricante selecionado não está mais na lista. Recarregue os dados.')),
        );
        setState(() => _saving = false);
        return;
      }

      // Se estamos editando, incluir o id para instruir o backend a atualizar
      if (widget.materialId != null) {
        data['material_id_materiais'] = widget.materialId;
      }

      if (kDebugMode) debugPrint('EntradaMateriais submit: $data');

      // Verificação remota simplificada (apenas se quiser confirmar existência básica)
      // Regra de empresa vinculada removida conforme solicitado.
      if (fabricanteId != null) {
        try {
          final remoto = await _ctrl.combosRepository.carregarPessoaPorId(fabricanteId);
          if (remoto == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fabricante não encontrado no servidor. Recarregue listas.')),
            );
            setState(() => _saving = false);
            return;
          }
        } catch (_) {
          // Silencia falha de verificação remota para não bloquear criação
        }
      }

      final resp = await _repo.salvar(data);
      if (resp['success'] == true) {
        final msg = descTruncada
            ? 'Entrada registrada (descrição truncada para 100 caracteres)'
            : 'Entrada registrada com sucesso';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.of(context).pop();
      } else {
        // Tentar mapear erros vindos do servidor para exibição inline
        if (resp['data'] != null && resp['data'] is Map) {
          final Map data = resp['data'] as Map;
          data.forEach((k, v) {
            try {
              final rawKey = k.toString();
              final msg = v?.toString();
              // Variantes a serem populadas no mapa de erros:
              // - chave original (ex: 'id_unidades_medidas' ou 'material_id_unidades_medidas')
              // - sem prefixo 'material_'
              // - sem prefixo 'id_' (ex: 'unidades_medidas') para cobertura heurística
              final keys = <String>{rawKey};
              if (rawKey.startsWith('material_')) keys.add(rawKey.replaceFirst('material_', ''));
              // também mapear se backend retornou 'material_id_x' -> 'id_x'
              if (rawKey.startsWith('material_id_')) keys.add(rawKey.replaceFirst('material_', ''));
              // variante sem 'id_' para heurísticas locais
              keys.toList().forEach((kk) {
                if (kk.startsWith('id_')) keys.add(kk.replaceFirst('id_', ''));
              });

              for (final key in keys) {
                _serverErrors[key] = msg;
              }
            } catch (_) {}
          });
        }

        final msg = resp['msg'] ?? resp['message'];
        if (msg != null && msg is String) {
          // heurística: se a mensagem mencionar um campo conhecido, associar
          final lower = msg.toLowerCase();
          final fieldMap = {
            'descri': 'descricao',
            'quantidade': 'quantidade',
            'unidade': 'id_unidades_medidas',
            'peso': 'peso',
            'lote': 'lote',
            'cod_barras': 'cod_barras',
            'data de fabrica': 'dt_fabricacao',
            'data de vencimento': 'dt_vencimento',
          };
          var assigned = false;
          fieldMap.forEach((k, v) {
            if (!assigned && lower.contains(k)) {
              _serverErrors[v] = msg;
              assigned = true;
            }
          });
          if (!assigned) {
            _serverErrors['global'] = msg;
          }
        }

        setState(() {});
        // Exibir mensagem global também
        final global = _serverErrors['global'] ?? _serverErrors.values.firstWhere((e) => e != null, orElse: () => null);
        if (global != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $global')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Dropdown original substituído pelo widget reativo; função removida.

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrada de Materiais', style: TextStyle(fontSize: 22)),
          flexibleSpace: AppBarLinearGradientWidget(),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    // Linha superior: Código de Barras + Descrição
                    _buildSection([
                      _buildField(Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codBarrasCtrl,
                              readOnly: widget.materialId != null,
                              enabled: widget.materialId == null,
                              decoration: InputDecoration(
                                labelText: 'Código de Barras *',
                                border: const OutlineInputBorder(),
                                errorText: _serverErrors['cod_barras'],
                                helperText: widget.materialId != null
                                    ? 'Não editável após cadastro'
                                    : 'GTIN/EAN (se existir)',
                              ),
                              validator: (v) {
                                if (_serverErrors['cod_barras'] != null) {
                                  return _serverErrors['cod_barras'];
                                }
                                if (widget.materialId != null) return null;
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe o código de barras';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: widget.materialId != null ? null : _scanCodigoBarras,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Ler'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                        ],
                      )),
                      _buildField(Column(
                        children: [
                          TextFormField(
                            controller: _nomeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Descrição do produto *',
                              border: const OutlineInputBorder(),
                              errorText: _serverErrors['descricao'],
                              helperText: 'Busque pelo nome (mín. 2 letras)',
                            ),
                            validator: (v) {
                              if (_serverErrors['descricao'] != null) return _serverErrors['descricao'];
                              return (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;
                            },
                            onChanged: _onDescricaoChanged,
                            onFieldSubmitted: (v) async {
                              // Fallback: se não há sugestões mas texto parece código de barras (somente dígitos ou >= 6 chars)
                              if (_produtoSugestoes.isEmpty && v.trim().length >= 6) {
                                final online = await _networkAccess.checkNetworkAcess();
                                if (!online) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: não foi possível buscar pelo código de barras')));
                                  return;
                                }
                                final prod = await _produtoRepo.buscarPorCodigoBarras(v.trim());
                                if (prod != null) {
                                  _aplicarProduto(prod);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto carregado pelo código')));
                                }
                              }
                            },
                          ),
                          if (_loadingSugestoes)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: const Row(children: [SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('Buscando...')]),
                            ),
                          if (!_loadingSugestoes && _produtoSugestoes.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _produtoSugestoes.length,
                                itemBuilder: (ctx, i) {
                                  final it = _produtoSugestoes[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(it.descricao, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(it.codigoBarras),
                                    onTap: () => _aplicarProduto(it),
                                  );
                                },
                              ),
                            ),
                          if (widget.materialId == null && !_produtoSelecionado && !_loadingSugestoes && _produtoSugestoes.isEmpty && _erroSugestoes == null && _nomeCtrl.text.trim().length >= 2)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: const Text('Nenhuma sugestão encontrada', style: TextStyle(fontSize: 12)),
                            ),
                          if (_erroSugestoes != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.red.shade50,
                              ),
                              child: Text(_erroSugestoes!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                            ),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Dias vencimento, dias venc. aberto, categoria
                    _buildSection([
                      _buildField(TextFormField(
                        controller: _diasVencCtrl,
                        readOnly: widget.materialId != null,
                        enabled: widget.materialId == null,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qtd. dias até o vencimento',
                          border: const OutlineInputBorder(),
                          hintText: 'Ex.: 30',
                          helperText: widget.materialId != null ? 'Não editável após cadastro' : 'Base para cálculo da validade;',
                        ),
                        onChanged: (v) {
                          // Se já houver fabricação, recalcular validade automaticamente
                          final dias = int.tryParse(v.trim());
                          if (_fabricacao != null && dias != null && dias >= 0) {
                            setState(() { _validade = _fabricacao!.add(Duration(days: dias)); });
                          }
                        },
                        validator: (v) {
                          if (_serverErrors['dias_vencimento'] != null) return _serverErrors['dias_vencimento'];
                          if (widget.materialId != null) return null;
                          final valor = v?.trim() ?? '';
                          if (valor.isEmpty) return 'Informe os dias até o vencimento';
                          final parsed = int.tryParse(valor);
                          if (parsed == null || parsed <= 0) return 'Informe um número válido';
                          return null;
                        },
                      )),
                      _buildField(TextFormField(
                        controller: _diasVencAbertoCtrl,
                        readOnly: widget.materialId != null,
                        enabled: widget.materialId == null,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qtd. dias venc. aberto',
                          border: const OutlineInputBorder(),
                          hintText: 'Ex.: 30',
                          helperText: widget.materialId != null ? 'Não editável após cadastro' : null,
                        ),
                      )),
                      _buildField(DropdownOptionReactive(
                        label: 'Categoria',
                        itemsRx: _ctrl.categorias,
                        selectedRx: _ctrl.categoriaSel,
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_materiais_categorias'],
                        validator: (_) => _ctrl.categoriaSel.value == null ? 'Selecione uma categoria' : null,
                        onChanged: (_) => _serverErrors.remove('id_materiais_categorias'),
                        onTapLoad: _ctrl.ensureCategoriasLoaded,
                        loadingRx: _ctrl.categoriasLoading,
                      )),
                    ]),
                    const SizedBox(height: 16),

                    _buildSection([
                      _buildField(DropdownOptionReactive(
                        label: 'Fornecedor',
                        itemsRx: _ctrl.fornecedores,
                        selectedRx: _ctrl.fornecedorSel,
                        onChanged: (_) => _serverErrors.remove('id_pessoas_fornecedor'),
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_pessoas_fornecedor'] ?? _serverErrors['fornecedor'],
                        onTapLoad: _ctrl.ensureFornecedoresLoaded,
                        loadingRx: _ctrl.fornecedoresLoading,
                      )),
                      _buildField(DropdownOptionReactive(
                        label: 'Fabricante',
                        itemsRx: _ctrl.fabricantes,
                        selectedRx: _ctrl.fabricanteSel,
                        onChanged: (_) => _serverErrors.remove('id_pessoas_fabricante'),
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_pessoas_fabricante'] ?? _serverErrors['fabricante'],
                        onTapLoad: _ctrl.ensureFabricantesLoaded,
                        loadingRx: _ctrl.fabricantesLoading,
                      )),
                    ]),
                    const SizedBox(height: 16),

                    _buildSection([
                      _buildField(DropdownOptionReactive(
                        label: 'Marca',
                        itemsRx: _ctrl.marcas,
                        selectedRx: _ctrl.marcaSel,
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_materiais_marcas'],
                        onChanged: (_) => _serverErrors.remove('id_materiais_marcas'),
                        onTapLoad: _ctrl.ensureMarcasLoaded,
                        loadingRx: _ctrl.marcasLoading,
                      )),
                    ]),
                    const SizedBox(height: 16),


                    // Datas: Fabricação e Vencimento
                    _buildSection([
                      _buildField(_dateField(
                        context: context,
                        label: 'Data de Fabricação',
                        value: _fabricacao,
                        df: df,
                        requiredField: true,
                        helperText: 'Informe a data em que o lote foi fabricado',
                        onPicked: (d) {
                          setState(() {
                            _fabricacao = d;
                            final dias = int.tryParse(_diasVencCtrl.text.trim());
                            if (_fabricacao != null && dias != null && dias >= 0) {
                              _validade = _fabricacao!.add(Duration(days: dias));
                            }
                          });
                        },
                      )),
                      _buildField(_dateField(
                        context: context,
                        label: 'Data de Vencimento',
                        value: _validade,
                        df: df,
                        requiredField: true,
                        helperText: 'Informe a validade do lote',
                        onPicked: (d) => setState(() => _validade = d),
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Peso, Quantidade, Lote, Nota Fiscal
                    _buildSection([
                      _buildField(TextFormField(
                        controller: _pesoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Peso *', border: const OutlineInputBorder(), hintText: 'Ex.: 3,00', errorText: _serverErrors['peso'], helperText: 'Peso na unidade escolhida'),
                        validator: (v) {
                          if (_serverErrors['peso'] != null) return _serverErrors['peso'];
                          return (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;
                        },
                      )),
                      // Unidade de medida deve vir após o Peso (padrão já definido no bootstrap)
                      _buildField(DropdownOptionReactive(
                        label: 'Unidade de medida',
                        itemsRx: _ctrl.unidades,
                        selectedRx: _ctrl.unidadeSel,
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_unidades_medidas'],
                        validator: (_) => _ctrl.unidadeSel.value == null ? 'Selecione a unidade' : null,
                        onChanged: (_) => _serverErrors.remove('id_unidades_medidas'),
                        onTapLoad: _ctrl.ensureUnidadesLoaded,
                        loadingRx: _ctrl.unidadesLoading,
                      )),
                      _buildField(TextFormField(
                        controller: _quantidadeCtrl,
                        readOnly: widget.materialId != null,
                        enabled: widget.materialId == null,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Quantidade *',
                          border: const OutlineInputBorder(),
                          hintText: 'Ex.: 11',
                          errorText: _serverErrors['quantidade'],
                          helperText: widget.materialId != null ? 'Não editável após cadastro' : 'Qtd total deste lote',
                        ),
                        validator: (v) {
                          if (_serverErrors['quantidade'] != null) return _serverErrors['quantidade'];
                          return (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;
                        },
                      )),
                      _buildField(TextFormField(
                        controller: _loteCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lote *',
                          border: const OutlineInputBorder(),
                          errorText: _serverErrors['lote'],
                          helperText: 'Lote conforme nota fiscal',
                        ),
                        validator: (v) {
                          if (_serverErrors['lote'] != null) return _serverErrors['lote'];
                          return (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;
                        },
                      )),
                      _buildField(TextFormField(
                        controller: _nroNotaCtrl,
                        decoration: InputDecoration(labelText: 'Nota Fiscal', border: const OutlineInputBorder(), hintText: 'Ex.: 123456789', errorText: _serverErrors['nro_nota'], helperText: 'Número da nota (opcional)'),
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Temperatura, SIF, Condição da embalagem
                    _buildSection([
                      _buildField(TextFormField(
                        controller: _temperaturaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Temperatura (°C)', border: const OutlineInputBorder(), hintText: 'Ex.: 10', errorText: _serverErrors['temperatura'], helperText: 'Temperatura de armazenamento (opcional)'),
                      )),
                      _buildField(TextFormField(
                        controller: _sifCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'SIF (registro)', border: const OutlineInputBorder(), hintText: 'Ex.: 11', errorText: _serverErrors['sif'], helperText: 'Registro SIF (se aplicável)'),
                      )),
                      _buildField(DropdownOptionReactive(
                        label: 'Condição da embalagem',
                        itemsRx: _ctrl.condicoesEmbalagem,
                        selectedRx: _ctrl.condicaoEmbalagemSel,
                        hint: 'Selecione...',
                        errorText: _serverErrors['id_embalagem_condicoes'],
                        onChanged: (_) => _serverErrors.remove('id_embalagem_condicoes'),
                        onTapLoad: _ctrl.ensureCondicoesEmbalagemLoaded,
                        loadingRx: _ctrl.condicoesLoading,
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Modo de Conservação (ChoiceChip) + Status
                    _buildSection([
                      _buildField(Obx(() {
                        final modos = _ctrl.modosConservacao;
                        if (modos.isEmpty) {
                          return InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Modo de conservação',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(child: Text('Nenhum item disponível. Toque para recarregar')),
                                IconButton(icon: const Icon(Icons.refresh), onPressed: _bootstrap, tooltip: 'Recarregar opções')
                              ],
                            ),
                          );
                        }
                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Modo de conservação',
                            border: OutlineInputBorder(),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: modos.map((m) {
                              final selected = _ctrl.modoConservacaoSel.value?.id.toString() == m.id.toString();
                              return ChoiceChip(
                                label: Text(m.descricao),
                                selected: selected,
                                onSelected: (_) => _ctrl.modoConservacaoSel.value = m,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        );
                      })),
                      _buildField(Obx(() => DropdownButtonFormField<String>(
                            initialValue: _statusSel.value,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'A', child: Text('Ativo')),
                              DropdownMenuItem(value: 'I', child: Text('Inativo')),
                            ],
                            onChanged: widget.materialId == null ? null : (v) => _statusSel.value = v ?? 'A',
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.isEmpty) ? 'Selecione status' : null,
                            disabledHint: const Text('Ativo'),
                          ))),
                    ]),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _salvar,
                        child: _saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.materialId != null ? 'Atualizar Entrada' : 'Registrar Entrada'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Helpers de layout para espaçamento consistente em grids horizontais.
Widget _buildField(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: child,
    );

Widget _buildSection(List<Widget> children) {
  return LayoutBuilder(builder: (ctx, constraints) {
    // Responsivo: se largura > 900 tenta 4 colunas, >650 3 colunas, >450 2 colunas, senão 1.
    int columns = 1;
    final w = constraints.maxWidth;
    if (w > 900) columns = 4; else if (w > 650) columns = 3; else if (w > 450) columns = 2;
    final colWidth = (w - (columns - 1) * 16) / columns;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: children
          .map((c) => SizedBox(width: columns == 1 ? w : colWidth, child: c))
          .toList(),
    );
  });
}

Widget _dateField({
  required BuildContext context,
  required String label,
  required DateTime? value,
  required ValueChanged<DateTime?> onPicked,
  required DateFormat df,
  bool requiredField = false,
  String? helperText,
}) {
  return FormField<DateTime>(
    validator: (_) {
      if (requiredField && value == null) return 'Selecione $label';
      return null;
    },
    builder: (state) {
      final displayValue = value ?? state.value;
      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: displayValue ?? DateTime.now(),
          );
          if (picked != null) {
            onPicked(picked);
            state.didChange(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            helperText: helperText,
            errorText: state.errorText,
          ),
          child: Text(displayValue == null ? '—' : df.format(displayValue)),
        ),
      );
    },
  );
}
