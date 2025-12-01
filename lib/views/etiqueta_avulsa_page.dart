import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/etiqueta_avulsa_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
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
  const EtiquetaAvulsaPage({super.key});

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
  // Lista de etiquetas geradas para pré-visualização antes da impressão
  List<EtiquetaModel> _etiquetasPreview = [];
  // Flag para impedir disparo múltiplo da impressão automática após setState/renderizações adicionais
  bool _impressaoAutomaticaDisparada = false;
  Widget? _widgetImpressao;

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    await _controller.loadCombos();
    if (_controller.combosLoadFailed.value) {
      _showSnack('Falha ao carregar unidades ou modos. Verifique a conexão/servidor.', color: Colors.orange);
    }
    if (_controller.unidades.isNotEmpty) {
      _unidadeSelecionada = _controller.unidades.firstWhereOrNull(
        (u) => (u.descricao ?? '').toLowerCase() == 'kg',
      );
    }
    if (mounted) setState(() {});
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
    final req = EtiquetaAvulsaRequest(
      descricao: _descricaoCtrl.text.trim(),
      validade: _validade,
      peso: peso,
      idUnidadesMedidas: _unidadeSelecionada!.id!,
      idModoConservacao: _modoSelecionado!.id!,
      quantidade: _quantidade.value,
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
      // Após renderização em tela, imprimir automaticamente
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Impede reentrância enquanto ciclo atual de impressão automática estiver em andamento
        if (_impressaoAutomaticaDisparada) return;
        _impressaoAutomaticaDisparada = true;
        try {
          await _imprimirSequencial();
        } finally {
          // Libera nova impressão automática em futuras criações
          _impressaoAutomaticaDisparada = false;
        }
      });
    } catch (e) {
      _showSnack('Erro ao criar etiqueta: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Função antiga de impressão manual via preview removida (fluxo agora automático).

  // Método antigo de impressão via Overlay removido após adoção de pré-visualização.

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
    final conectado =
        impressorasController.getPrinterConnectionState.value ==
            PrinterConnectionState.connected;
    if (!conectado) {
      _showSnack('Conecte uma impressora para imprimir', color: Colors.orange);
      return;
    }
    bool algumSucesso = false;
    for (final etiqueta in _etiquetasPreview) {
      final key = GlobalKey();
      setState(() {
        _widgetImpressao =
            impressorasController.getSizeLabelPrint.value == SizeLabelPrint.$50_x_50
                ? Etiqueta50x50Widget(
                    etiquetaModel: etiqueta,
                    fgImprimir: true,
                    globalKey: key,
                    sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                  )
                : EtiquetaWidget(
                    etiquetaModel: etiqueta,
                    fgImprimir: true,
                    globalKey: key,
                    sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                  );
      });
      await Future.delayed(const Duration(seconds: 1), () async {
        try {
          await impressorasController.enviaEtiqueta(
            key: key,
            numEtiqueta: etiqueta.numEtiqueta,
          );
          algumSucesso = true;
        } catch (e) {
          _showSnack('Falha impressão etiqueta: ${_formatError(e)}');
        }
      });
    }
    setState(() {
      _widgetImpressao = null;
    });
    if (algumSucesso) {
      _limparFormulario();
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
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _loadPrinters() async {
    final bluetooth = await impressorasController.isBluetoothEnabled();
    if (!bluetooth) {
      _showSnack('Ative o bluetooth do dispositivo');
      return;
    }
    await impressorasController.loadImpressoras();
    _modalListaImpressoras();
  }

  void _connectDevice(BluetoothDevice device) {
    impressorasController.connectDevices(device: device);
  }

  void _disconnectDevice() {
    impressorasController.disconnectDevice();
  }

  void _setLayout(SizeLabelPrint sizeLabelPrint) {
    impressorasController.setSizeLabelPrint = sizeLabelPrint;
    setState(() {});
  }

  String _formatError(Object error) {
    if (error is CustomException) {
      return error.message;
    }
    return error.toString();
  }

  void _modalListaImpressoras() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          title: const Text(
            'Impressão',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            children: [
              const Text('Layout', style: TextStyle(fontSize: 18)),
              Obx(() {
                return Row(
                  children: [
                    Row(
                      children: [
                        Radio<SizeLabelPrint>(
                          activeColor: Colors.blue,
                          value: SizeLabelPrint.$50_x_30,
                          groupValue:
                              impressorasController.getSizeLabelPrint.value,
                          onChanged: (value) {
                            if (value != null) _setLayout(value);
                          },
                        ),
                        const Text('50 x 30'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<SizeLabelPrint>(
                          activeColor: Colors.blue,
                          value: SizeLabelPrint.$50_x_50,
                          groupValue:
                              impressorasController.getSizeLabelPrint.value,
                          onChanged: (value) {
                            if (value != null) _setLayout(value);
                          },
                        ),
                        const Text('50 x 50'),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Lista de Impressoras',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Obx(
                  () => impressorasController.getStatusListaImpressoras.value ==
                          StatusListaImpressoras.success
                      ? ListView.builder(
                          itemCount:
                              impressorasController.getListaImpressoras.length,
                          itemBuilder: (context, index) {
                            final device =
                                impressorasController.getListaImpressoras[index];
                            return ListTile(
                              title: Text(device.name),
                              subtitle: Text(device.address),
                              trailing: Obx(() {
                                final impressoraAtual = impressorasController
                                    .getImpressoraConectada.value;
                                final conectado =
                                    impressoraAtual.address.isNotEmpty &&
                                        impressoraAtual.address ==
                                            device.address;
                                return IconButton(
                                  icon: Obx(() {
                                    final state = impressorasController
                                        .getPrinterConnectionState.value;
                                    final isThisDevice = conectado;
                                    Color iconColor = Colors.red;
                                    IconData iconData = Icons.print_disabled_outlined;
                                    if (isThisDevice && state == PrinterConnectionState.connected) {
                                      iconColor = Colors.green;
                                      iconData = Icons.print_outlined;
                                    } else if (isThisDevice && state == PrinterConnectionState.connecting) {
                                      iconColor = Colors.amber;
                                      iconData = Icons.sync;
                                    }
                                    return Icon(iconData, color: iconColor);
                                  }),
                                  onPressed: () {
                                    if (conectado) {
                                      _disconnectDevice();
                                    } else {
                                      _connectDevice(device);
                                    }
                                  },
                                );
                              }),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Etiqueta avulsa'),
          flexibleSpace: AppBarLinearGradientWidget(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
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
                          decoration: const InputDecoration(
                            labelText: 'Descrição *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
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
                            decoration: const InputDecoration(
                              labelText: 'Validade',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _validade == null ? '—' : df.format(_validade!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pesoCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Peso *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Obrigatório'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<UnidadeMedidaModel>(
                                value: _unidadeSelecionada,
                                items: _controller.unidades
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                            u.descricao ?? u.sigla ?? '-'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _unidadeSelecionada = value);
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Unidade *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Modo de conservação *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _controller.modos.map((modo) {
                                final selecionado =
                                    _modoSelecionado?.id == modo.id;
                                return ChoiceChip(
                                  label: Text(modo.descricao ?? '-'),
                                  selected: selecionado,
                                  onSelected: (_) {
                                    setState(() => _modoSelecionado = modo);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          return Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_quantidade.value > 1) {
                                    _quantidade.value--;
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                _quantidade.value.toString(),
                                style: const TextStyle(fontSize: 20),
                              ),
                              IconButton(
                                onPressed: () => _quantidade.value++,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const SizedBox(width: 12),
                              const Text('Quantidade'),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _salvando ? null : _criar,
                          icon: _salvando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Gerar etiquetas'),
                        ),
                        const SizedBox(height: 24),
                        if (_etiquetasPreview.isNotEmpty) ...[
                          ...List.generate(_etiquetasPreview.length, (index) {
                            final e = _etiquetasPreview[index];
                            final layout = impressorasController.getSizeLabelPrint.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                          child: layout == SizeLabelPrint.$50_x_50
                              ? Etiqueta50x50Widget(
                                  etiquetaModel: e,
                                  fgImprimir: false,
                                  globalKey: null,
                                  sizeLabelPrint: layout,
                                )
                              : EtiquetaWidget(
                                  etiquetaModel: e,
                                  fgImprimir: false,
                                  globalKey: null,
                                  sizeLabelPrint: layout,
                                ),
                        );
                          }),
                        ],
                      ],
                    ),
                  ),
                  PrintingStatusOverlayWidget(controller: impressorasController),
                  Positioned(
                    left: -10000,
                    top: -10000,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: _widgetImpressao ?? const SizedBox(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
