import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/repositories/etiqueta_repository.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class EtiquetaAvulsaPage extends StatefulWidget {
  const EtiquetaAvulsaPage({super.key});

  @override
  State<EtiquetaAvulsaPage> createState() => _EtiquetaAvulsaPageState();
}

class _EtiquetaAvulsaPageState extends State<EtiquetaAvulsaPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EtiquetaRepository();

  final _descricaoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  DateTime? _validade;

  List<UnidadeMedidaModel> _unidades = [];
  UnidadeMedidaModel? _umSelecionada;

  List<ModoConservacaoModel> _modos = [];
  ModoConservacaoModel? _modoSel;

  bool _carregando = true;
  bool _enviando = false;
  int _qtd = 1;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _carregando = true);
    try {
      final units = await _repo.listaUnidadesMedidas(status: 'A');
      final modos = await _repo.listaModosConservacao(status: 'A');
      setState(() {
        _unidades = units;
        _umSelecionada = units.isNotEmpty ? units.first : null;
        _modos = modos;
        _modoSel = modos.isNotEmpty ? modos.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final req = EtiquetaAvulsaRequest(
      descricao: _descricaoCtrl.text.trim(),
      validade: _validade,
      peso: _pesoCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_pesoCtrl.text.replaceAll(',', '.')),
      idUnidadesMedidas: _umSelecionada?.idUnidadesMedidas,
      idModoConservacao: _modoSel?.id,
      quantidade: _qtd,
    );

    setState(() => _enviando = true);
    try {
      await _repo.criarEtiquetaAvulsa(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiqueta(s) avulsa(s) criada(s)')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gerar etiqueta avulsa", style: TextStyle(fontSize: 22)),
          flexibleSpace: AppBarLinearGradientWidget(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _descricaoCtrl,
                      decoration: const InputDecoration(labelText: 'Descrição do Produto *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),

                    // Validade (date picker)
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: _validade ?? DateTime.now(),
                        );
                        if (picked != null) setState(() => _validade = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Validade do Produto', border: OutlineInputBorder()),
                        child: Text(_validade == null ? '—' : df.format(_validade!)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Peso + UM (lado a lado)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pesoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Peso', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<UnidadeMedidaModel>(
                            value: _umSelecionada,
                            items: _unidades.map((u) =>
                              DropdownMenuItem(value: u, child: Text(u.descricao ?? ''))).toList(),
                            onChanged: (v) => setState(() => _umSelecionada = v),
                            decoration: const InputDecoration(labelText: 'Unidade de medida', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Modo de Conservação (título + lista)
                    const Text('Modo de Conservação', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _modos.map((m) {
                        final selected = _modoSel?.id == m.id;
                        return ChoiceChip(
                          label: Text(m.descricao ?? ''),
                          selected: selected,
                          onSelected: (_) => setState(() => _modoSel = m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Quantidade +/- (igual padrão dos botões/tamanho)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantidade', style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() { if (_qtd > 1) _qtd--; }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_qtd', style: const TextStyle(fontSize: 20)),
                            IconButton(
                              onPressed: () => setState(() { _qtd++; }),
                              icon: const Icon(Icons.add_circle_outline_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _enviando ? null : _enviar,
                        child: _enviando
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Gerar Etiqueta'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
