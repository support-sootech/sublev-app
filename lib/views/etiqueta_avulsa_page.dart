import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/etiqueta_avulsa_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
import 'package:ootech/models/catalogo_avulso_model.dart';
import 'package:ootech/controller/catalogo_avulso_controller.dart'; 
import 'package:ootech/models/etiqueta_model.dart'; 
import 'package:ootech/models/etiqueta_avulsa_models.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_50x50_widget.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:ootech/views/widgets/printer_status_icon_widget.dart';
import 'package:ootech/views/widgets/printing_status_overlay_widget.dart';

class EtiquetaAvulsaPage extends StatefulWidget {
  final bool isCatalogoMode;
  final CatalogoAvulsoModel? catalogoItem;
  /// Modos: 'novo', 'gerar_favorito', 'gerar_comum', 'editar_catalogo'
  final String? modo;

  const EtiquetaAvulsaPage({
      super.key, 
      this.isCatalogoMode = false, 
      this.catalogoItem,
      this.modo,
  });

  @override
  State<EtiquetaAvulsaPage> createState() => _EtiquetaAvulsaPageState();
}

class _EtiquetaAvulsaPageState extends State<EtiquetaAvulsaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  DateTime? _validade;
  final RxInt _quantidade = 1.obs;

  late final EtiquetaAvulsaController _controller =
      Get.find<EtiquetaAvulsaController>();
  late final NiimbotImpressorasController impressorasController =
      Get.find<NiimbotImpressorasController>();

  UnidadeMedidaModel? _unidadeSelecionada;
  ModoConservacaoModel? _modoSelecionado;
  bool _salvando = false;
  List<EtiquetaModel> _etiquetasPreview = [];
  bool _impressaoAutomaticaDisparada = false;
  Widget? _widgetImpressao;

  bool _salvarCatalogo = false; // Checkbox para novos/comuns
  bool _manterFavorito = true;  // Switch para edicao de catalogo
  
  bool get _isReadOnly => widget.modo == 'gerar_favorito';
  bool get _isEdicaoCatalogo => widget.modo == 'editar_catalogo';
  
  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    await _controller.loadCombos();
    if (_controller.combosLoadFailed.value) {
      _showSnack('Falha ao carregar unidades ou modos.', color: Colors.orange);
    }
    
    if (widget.catalogoItem != null) {
        final item = widget.catalogoItem!;
        _descricaoCtrl.text = item.descricao;
        
        // Formatacao inteligente do peso para remover .000 e usar virgula se houver decimal
        final p = item.peso;
        _pesoCtrl.text = (p % 1 == 0) 
            ? p.toInt().toString() 
            : p.toString().replaceAll('.', ',');

        // Selecionar Combos
        if (_controller.unidades.isNotEmpty) {
             _unidadeSelecionada = _controller.unidades.firstWhereOrNull((u) => u.id == item.idUnidadesMedidas);
        }
        if (_controller.modos.isNotEmpty) {
             _modoSelecionado = _controller.modos.firstWhereOrNull((m) => m.id == item.idModoConservacao);
        }
        
        // Calcular Validade
        if (item.qtdeDiasVencimento > 0) {
            _validade = DateTime.now().add(Duration(days: item.qtdeDiasVencimento));
        }
        
        // Inicializar Flags
        if (_isEdicaoCatalogo) {
            _manterFavorito = item.favorito;
        } else {
           // Gerar (Favorito ou Comum): Padrao nao salvar novo favorito automatico
           _salvarCatalogo = false; 
        }
    } else {
        // Modo Novo
        if (_controller.unidades.isNotEmpty) {
          _unidadeSelecionada = _controller.unidades.firstWhereOrNull(
            (u) => (u.descricao ?? '').toLowerCase() == 'kg',
          );
        }
    }
    
    // Armazena valores iniciais para verificar mudancas
    if (widget.modo == 'gerar_favorito') {
        _initialPeso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
        _initialUnidade = _unidadeSelecionada;
    }
    
    if (mounted) setState(() {});
  }

  // Variaveis para controle de alteracao em favoritos
  double? _initialPeso;
  UnidadeMedidaModel? _initialUnidade;
  
  bool get _hasChanges {
      if (widget.modo != 'gerar_favorito') return false;
      final currentPeso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
      final currentUn = _unidadeSelecionada;
      
      // Compara Peso (precisao normal)
      if ((currentPeso - (_initialPeso ?? 0)).abs() > 0.001) return true;
      // Compara Unidade ID
      if (currentUn?.id != _initialUnidade?.id) return true;
      
      return false;
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_unidadeSelecionada?.id == null) {
      _showSnack('Selecione a unidade de medida');
      return;
    }
    if (_modoSelecionado?.id == null) {
      _showSnack('Selecione o modo de conservação');
      return;
    }

    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    
    // Define se salva no catalogo/favorito
    bool flagSalvar = false;

    if (_isEdicaoCatalogo) {
       // Edicao direta do item catalogo: mantem o status do switch
       flagSalvar = _manterFavorito; 
    } else {
       // Geracao (Novo, Comum ou Gerar Favorito)
       // Se for 'gerar_favorito', o usuario pediu UX de Template:
       // "Somente podera alterar peso... mudamos o icone para liga/desliga... se eu manter sempre ele como favorito... ira criar novo item favorito"
       // SOLUCAO: Padrao FALSE para novos favoritos. Se ele quiser salvar o template EDITADO, ele liga o switch.
       flagSalvar = _salvarCatalogo; 
    }

    final req = EtiquetaAvulsaRequest(
      descricao: _descricaoCtrl.text.trim(),
      validade: _validade,
      peso: peso,
      idUnidadesMedidas: _unidadeSelecionada!.id!,
      idModoConservacao: _modoSelecionado!.id!,
      quantidade: _quantidade.value,
      salvarCatalogo: flagSalvar,
    );

    setState(() => _salvando = true);
    try {
      final AvulsaResponse resp = await _controller.criar(req);
      if (!resp.success || resp.data.isEmpty) {
        throw Exception('Nenhuma etiqueta retornada pelo servidor');
      }
      final etiquetas = resp.data.map(_mapToEtiqueta).toList()
        ..sort((a, b) {
          final numA = a.numEtiqueta ?? 0;
          final numB = b.numEtiqueta ?? 0;
          return numA.compareTo(numB);
        });
      _etiquetasPreview = etiquetas;
      setState(() {});
      
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_impressaoAutomaticaDisparada) return;
        _impressaoAutomaticaDisparada = true;
        try {
          await _imprimirSequencial();
        } finally {
          _impressaoAutomaticaDisparada = false;
        }
      });
      
      // Se era catalogo gerar favorito, volta pra lista após sucesso?
      // O usuario nao especificou, mas padrao App é ficar na tela ou limpar?
      // Vou manter o padrao atual (preview -> limpar)
    } catch (e) {
      _showSnack('Erro ao criar etiqueta: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _salvarEdicaoItem() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_unidadeSelecionada?.id == null) {
      _showSnack('Selecione a unidade de medida');
      return;
    }
    
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    
    int dias = 0;
    if (_validade != null) {
        final now = DateTime.now();
        // Zera horas para calculo correto de dias
        final v = DateTime(_validade!.year, _validade!.month, _validade!.day);
        final n = DateTime(now.year, now.month, now.day);
        dias = v.difference(n).inDays;
        if (dias < 0) dias = 0;
    }

    final Map<String, dynamic> data = {
        'id': widget.catalogoItem?.id,
        'descricao': _descricaoCtrl.text.trim(),
        'qtde_dias_vencimento': dias,
        'peso': peso,
        'id_unidades_medidas': _unidadeSelecionada?.id,
        'id_modo_conservacao': _modoSelecionado?.id,
        'favorito': _manterFavorito
    };

    setState(() => _salvando = true);
    
    CatalogoAvulsoController catCtrl;
    try {
        catCtrl = Get.find<CatalogoAvulsoController>();
    } catch (_) {
        catCtrl = Get.put(CatalogoAvulsoController());
    }
    
    try {
        final res = await catCtrl.salvarItem(data);
        if (res['success'] == true) {
             _showSnack('Item salvo com sucesso!', color: Colors.green);
             catCtrl.carregar(); 
             await Future.delayed(const Duration(seconds: 1));
             if (mounted) Navigator.pop(context);
        } else {
             _showSnack('Erro ao salvar: ${res['msg']}');
        }
    } catch (e) {
        _showSnack('Erro: $e');
    } finally {
        if (mounted) setState(() => _salvando = false);
    }
  }

  EtiquetaModel _mapToEtiqueta(EtiquetaAvulsaItem item) {
    return EtiquetaModel(
      idEtiquetas: item.idEtiquetas,
      descricao: item.descricao,
      idMateriaisFracionados: item.idMateriaisFracionados,
      idMateriais: item.idMateriais,
      status: item.status,
      idUsuarios: item.idUsuarios,
      dsMaterial: item.dsMaterial,
      dsUnidadesMedidas: item.dsUnidadesMedidas,
      dsModoConservacao: item.dsModoConservacao,
      qtdFracionada: item.qtdFracionadaDisplay,
      dtFracionamento: item.dtFracionamento,
      dtFracionamentoReduzido: item.dtFracionamentoReduzido,
      dtVencimento: item.dtVencimento,
      dtVencimentoReduzido: item.dtVencimentoReduzido,
      nmPessoa: item.nmPessoa,
      nmPessoaAbreviado: item.nmPessoaAbreviado,
      nmSetor: item.nmSetor,
      numEtiqueta: item.numEtiqueta,
    );
  }

  Future<void> _imprimirSequencial() async {
    if (_etiquetasPreview.isEmpty) return;
    final conectado = impressorasController.getPrinterConnectionState.value == PrinterConnectionState.connected;
    if (!conectado) {
      _showSnack('Conecte uma impressora para imprimir', color: Colors.orange);
      return;
    }
    bool algumSucesso = false;
    for (final etiqueta in _etiquetasPreview) {
      final key = GlobalKey();
      setState(() {
        _widgetImpressao = impressorasController.getSizeLabelPrint.value == SizeLabelPrint.$50_x_50
                ? Etiqueta50x50Widget(etiquetaModel: etiqueta, fgImprimir: true, globalKey: key, sizeLabelPrint: impressorasController.getSizeLabelPrint.value)
                : EtiquetaWidget(etiquetaModel: etiqueta, fgImprimir: true, globalKey: key, sizeLabelPrint: impressorasController.getSizeLabelPrint.value);
      });
      await Future.delayed(const Duration(seconds: 1), () async {
        try {
          await impressorasController.enviaEtiqueta(key: key, numEtiqueta: etiqueta.numEtiqueta);
          algumSucesso = true;
        } catch (e) { _showSnack('Falha impressão: ${_formatError(e)}'); }
      });
    }
    setState(() { _widgetImpressao = null; });
    if (algumSucesso) {
       // Se for Gerar Favorito (ReadOnly), talvez voltar pra tela anterior faça mais sentido?
       // Mas o usuario nao pediu. Vou limpar pra permitir nova geracao.
       if (!_isReadOnly) _limparFormulario(); 
       else _showSnack('Impressão concluída.', color: Colors.green);
    }
  }

  void _limparFormulario() {
    _descricaoCtrl.clear();
    _pesoCtrl.clear();
    _validade = null;
    _quantidade.value = 1;
    _etiquetasPreview = [];
    setState(() {});
  }

  void _showSnack(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Center(child: Text(message)), backgroundColor: color),
    );
  }

  // ... (Metodos de impressora mantidos: _loadPrinters, _connectDevice, etc)
  Future<void> _loadPrinters() async {
    final bluetooth = await impressorasController.isBluetoothEnabled();
    if (!bluetooth) {
      _showSnack('Ative o bluetooth do dispositivo');
      return;
    }
    await impressorasController.loadImpressoras();
    _modalListaImpressoras();
  }
  void _connectDevice(BluetoothDevice device) => impressorasController.connectDevices(device: device);
  void _disconnectDevice() => impressorasController.disconnectDevice();
  void _setLayout(SizeLabelPrint sizeLabelPrint) { impressorasController.setSizeLabelPrint = sizeLabelPrint; setState(() {}); }
  String _formatError(Object error) => (error is CustomException) ? error.message : error.toString();
  
  void _modalListaImpressoras() {
    // Mesma implementacao do modal, vou simplificar a escrita no replace pois nao mudou.
    // ... codigo do modal ...
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          title: const Text('Impressão', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            children: [
              const Text('Layout', style: TextStyle(fontSize: 18)),
              Obx(() => Row(children: [
                    Row(children: [Radio<SizeLabelPrint>(activeColor: Colors.blue, value: SizeLabelPrint.$50_x_30, groupValue: impressorasController.getSizeLabelPrint.value, onChanged: (v) {if(v!=null)_setLayout(v);}), const Text('50 x 30')]),
                    Row(children: [Radio<SizeLabelPrint>(activeColor: Colors.blue, value: SizeLabelPrint.$50_x_50, groupValue: impressorasController.getSizeLabelPrint.value, onChanged: (v) {if(v!=null)_setLayout(v);}), const Text('50 x 50')])
              ])),
              const SizedBox(height: 12),
              const Text('Lista de Impressoras', style: TextStyle(fontSize: 18)),
              SizedBox(height: MediaQuery.of(context).size.height * 0.25, width: MediaQuery.of(context).size.width * 0.8,
                child: Obx(() => impressorasController.getStatusListaImpressoras.value == StatusListaImpressoras.success
                      ? ListView.builder(itemCount: impressorasController.getListaImpressoras.length, itemBuilder: (ctx, idx) {
                            final d = impressorasController.getListaImpressoras[idx];
                            return ListTile(title: Text(d.name), subtitle: Text(d.address), trailing: Obx(() {
                                final curr = impressorasController.getImpressoraConectada.value;
                                final con = curr.address.isNotEmpty && curr.address == d.address;
                                final st = impressorasController.getPrinterConnectionState.value;
                                return IconButton(icon: Icon((con && st == PrinterConnectionState.connected) ? Icons.print_outlined : ((con && st == PrinterConnectionState.connecting) ? Icons.sync : Icons.print_disabled_outlined), color: (con && st == PrinterConnectionState.connected) ? Colors.green : ((con && st == PrinterConnectionState.connecting) ? Colors.amber : Colors.red)), 
                                onPressed: () => con ? _disconnectDevice() : _connectDevice(d));
                            }));
                        })
                      : const Center(child: CircularProgressIndicator())),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    
    // Titulo condicional
    String title = 'Gerar Etiqueta Avulsa'; // default (menor)
    if (_isEdicaoCatalogo) title = 'Editar Item Catálogo';
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 18)), // Fonte menor
          flexibleSpace: AppBarLinearGradientWidget(),
          centerTitle: true, // Centralize
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isEdicaoCatalogo) // Sem impressora na tela de edição
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PrinterStatusIconWidget(controller: impressorasController, onTap: _loadPrinters),
            ),
          ],
        ),
        body: _controller.loadingCombos.value
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          controller: _descricaoCtrl,
                          // Bloquear descricao se for favorito, pois define a identidade do item
                          enabled: !_isReadOnly, 
                          decoration: InputDecoration(
                            labelText: 'Descrição *',
                            border: const OutlineInputBorder(),
                            // Visual indication of disabled state
                            filled: _isReadOnly,
                            fillColor: _isReadOnly ? Colors.grey.shade200 : null,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          // Bloqueio rigoroso de validade para favoritos (regra de negocio)
                          onTap: _isReadOnly ? null : () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: _validade ?? DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _validade = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Validade',
                              border: const OutlineInputBorder(),
                              filled: _isReadOnly,
                              fillColor: _isReadOnly ? Colors.grey.shade200 : null,
                            ),
                            child: Text(
                              _validade == null ? '—' : df.format(_validade!),
                              style: TextStyle(color: _isReadOnly ? Colors.grey.shade700 : Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pesoCtrl,
                                // Peso sempre liberado (pedido do usuario)
                                enabled: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Peso *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                                onChanged: (v) => setState((){}), // Forçar rebuild para checar changes no peso
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<UnidadeMedidaModel>(
                                  value: _unidadeSelecionada,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidade *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _controller.unidades.map((u) => DropdownMenuItem(value: u, child: Text(u.descricao ?? u.sigla ?? '-'))).toList(),
                                  // Unidade liberada
                                  onChanged: (v) => setState(() {
                                    _unidadeSelecionada = v;
                                    // SetState já ocorre aqui
                                  }),
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Modo de conservação *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            // Bloquear modo conservacao se for favorito (identidade do produto)
                            IgnorePointer(
                                ignoring: _isReadOnly,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _controller.modos.map((modo) {
                                    final selecionado = _modoSelecionado?.id == modo.id;
                                    return ChoiceChip(
                                      label: Text(modo.descricao ?? '-'),
                                      selected: selecionado,
                                      selectedColor: _isReadOnly ? Colors.grey.shade300 : null,
                                      onSelected: (v) {
                                          if (!_isReadOnly) setState(() => _modoSelecionado = modo);
                                      },
                                    );
                                  }).toList(),
                                ),
                            ),
                          ],
                        ), 
                        const SizedBox(height: 12),
                        // Quantidade
                        if (!_isEdicaoCatalogo) ...[
                            Obx(() => Row(children: [
                                  IconButton(onPressed: () {if (_quantidade.value > 1) _quantidade.value--;}, icon: const Icon(Icons.remove_circle_outline)),
                                  Text(_quantidade.value.toString(), style: const TextStyle(fontSize: 20)),
                                  IconButton(onPressed: () => _quantidade.value++, icon: const Icon(Icons.add_circle_outline)),
                                  const SizedBox(width: 12),
                                  const Text('Quantidade de Etiquetas'),
                            ])),
                            const SizedBox(height: 12),
                        ],

                        // Seção Favorito
                        // Seção Favorito / Salvar Catalogo
                        if (_isEdicaoCatalogo) ...[
                             // Switch para manter favorito (Edição Direta)
                             SwitchListTile(
                                 title: const Text("Manter como Favorito"),
                                 value: _manterFavorito, 
                                 activeColor: Colors.amber, 
                                 activeTrackColor: Colors.amber.withOpacity(0.5),
                                 inactiveThumbColor: Colors.grey,
                                 inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                 onChanged: (v) => setState(() => _manterFavorito = v)
                             ),
                        ] else ...[
                             // Geracao (Novo, Comum ou Template Favorito)
                             
                             // CASO 1: Favorito SEM ALTERAÇÕES -> Mostra Banner, esconde checkbox (usa template)
                             if (widget.modo == 'gerar_favorito' && !_hasChanges) 
                                Container(
                                   margin: const EdgeInsets.only(bottom: 12),
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                   child: Row(children: const [
                                       Icon(Icons.star, color: Colors.amber),
                                       SizedBox(width: 8),
                                       Expanded(child: Text("Item Favorito (Template)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16))),
                                   ]),
                                ),

                             // CASO 2: Favorito COM ALTERAÇÕES -> Mostra Opção de Salvar NOVO
                             if (widget.modo == 'gerar_favorito' && _hasChanges) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, left: 16),
                                  child: Row(children: const [
                                     Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                                     SizedBox(width: 6),
                                     Expanded(child: Text("Alterações detectadas. Deseja salvar como novo favorito?", style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic)))
                                  ]),
                                ),
                                CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Salvar como novo favorito'),
                                    subtitle: const Text('Cria um novo item na lista de favoritos com estes dados'),
                                    value: _salvarCatalogo,
                                    activeColor: Colors.amber,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() => _salvarCatalogo = v ?? false),
                                ),
                             ],

                             // CASO 3: Novos ou Comuns -> Checkbox de salvar favorito Padrao
                             if (widget.modo != 'gerar_favorito')
                                CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Salvar como favorito (Catálogo avulso)'),
                                    value: _salvarCatalogo,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() => _salvarCatalogo = v ?? false),
                                ),
                        ],
                        
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _salvando ? null : (_isEdicaoCatalogo ? _salvarEdicaoItem : _criar),
                          icon: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isEdicaoCatalogo ? Icons.save : Icons.print),
                          label: Text(_isEdicaoCatalogo ? 'Salvar Alterações' : 'Gerar etiquetas'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        // ... Preview (somente se não for edição)
                        if (!_isEdicaoCatalogo && _etiquetasPreview.isNotEmpty) ...[
                           const SizedBox(height: 24),
                           const Text("Pré-visualização:", style: TextStyle(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 8),
                           ...List.generate(_etiquetasPreview.length, (index) {
                                final e = _etiquetasPreview[index];
                                final layout = impressorasController.getSizeLabelPrint.value;
                                return Padding(padding: const EdgeInsets.only(bottom: 16), child: layout == SizeLabelPrint.$50_x_50 ? Etiqueta50x50Widget(etiquetaModel: e, fgImprimir: false, globalKey: null, sizeLabelPrint: layout) : EtiquetaWidget(etiquetaModel: e, fgImprimir: false, globalKey: null, sizeLabelPrint: layout));
                           }),
                        ],
                      ],
                    ),
                  ),
                  PrintingStatusOverlayWidget(controller: impressorasController),
                  Positioned(left: -10000, top: -10000, child: SizedBox(width: MediaQuery.of(context).size.width, child: _widgetImpressao ?? const SizedBox())),
                ],
              ),
      ),
    );
  }
}
