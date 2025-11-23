import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/controller/etiqueta_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_50x50_widget.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:ootech/views/widgets/printer_status_icon_widget.dart';
import 'package:ootech/views/widgets/printing_status_overlay_widget.dart';

class EtiquetasPage extends StatefulWidget {
  const EtiquetasPage({super.key});

  @override
  State<EtiquetasPage> createState() => _EtiquetasPageState();
}

class _EtiquetasPageState extends State<EtiquetasPage> {
  final EtiquetaController etiquetaController = EtiquetaController();
  final NiimbotImpressorasController impressorasController =
      Get.find<NiimbotImpressorasController>();

  // Lazy load local cache (client-side pagination)
  final List<EtiquetaModel> _visible = [];
  static const int _pageSize = 40; // ajuste conforme memória/performance
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadListaEtiquetas();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadListaEtiquetas() async {
    try {
      await etiquetaController.loadListaEtiquetas();
      _rebuildVisible(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rebuildVisible({bool reset = false}) {
    final all = etiquetaController.getListaEtiquetdas;
    if (reset) {
      _visible
        ..clear()
        ..addAll(all.take(_pageSize));
      _hasMore = all.length > _visible.length;
      _loadingMore = false;
      setState(() {});
    } else {
      // append next slice
      if (_loadingMore || !_hasMore) return;
      _loadingMore = true;
      final current = _visible.length;
      final nextSlice = all.skip(current).take(_pageSize).toList();
      _visible.addAll(nextSlice);
      _hasMore = _visible.length < all.length;
      _loadingMore = false;
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _rebuildVisible();
    }
  }

  void _setLayout({required SizeLabelPrint sizeLabelPrint}) {
    impressorasController.setSizeLabelPrint = sizeLabelPrint;
    setState(() {});
  }

  void _loadPrinters() async {
    final fgBt = await impressorasController.isBluetoothEnabled();
    if (!fgBt) {
      _scaffoldMessenger(message: 'Bluetooth desligado no aparelho');
      return;
    }
    await impressorasController.loadImpressoras();
    _modalListaImpressoras();
  }

  void _connectDevice({required BluetoothDevice device}) async {
    await impressorasController.connectDevices(device: device);
  }

  void _disconnectDevice() async {
    await impressorasController.disconnectDevice();
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
                    Row(children: [
                      Radio<SizeLabelPrint>(
                        activeColor: Colors.blue,
                        value: SizeLabelPrint.$50_x_30,
                        groupValue: impressorasController.getSizeLabelPrint.value,
                        onChanged: (value) {
                          if (value != null) _setLayout(sizeLabelPrint: value);
                        },
                      ),
                      const Text('50 x 30'),
                    ]),
                    Row(children: [
                      Radio<SizeLabelPrint>(
                        activeColor: Colors.blue,
                        value: SizeLabelPrint.$50_x_50,
                        groupValue: impressorasController.getSizeLabelPrint.value,
                        onChanged: (value) {
                          if (value != null) _setLayout(sizeLabelPrint: value);
                        },
                      ),
                      const Text('50 x 50'),
                    ]),
                  ],
                );
              }),
              const SizedBox(height: 12),
              const Text('Lista de Impressoras', style: TextStyle(fontSize: 18)),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Obx(() {
                  return impressorasController.getStatusListaImpressoras.value ==
                          StatusListaImpressoras.success
                      ? ListView.builder(
                          itemCount: impressorasController.getListaImpressoras.length,
                          itemBuilder: (context, index) {
                            final device = impressorasController.getListaImpressoras[index];
                            return ListTile(
                              title: Text(device.name),
                              subtitle: Text(device.address),
                              trailing: Obx(() {
                                final atual = impressorasController.getImpressoraConectada.value;
                                final conectado = atual.address.isNotEmpty && atual.address == device.address;
                                final state = impressorasController.getPrinterConnectionState.value;
                                Color iconColor = Colors.red;
                                IconData iconData = Icons.print_disabled_outlined;
                                if (conectado && state == PrinterConnectionState.connected) {
                                  iconColor = Colors.green;
                                  iconData = Icons.print_outlined;
                                } else if (conectado && state == PrinterConnectionState.connecting) {
                                  iconColor = Colors.amber;
                                  iconData = Icons.sync;
                                }
                                return IconButton(
                                  icon: Icon(iconData, color: iconColor),
                                  onPressed: () {
                                    if (conectado) {
                                      _disconnectDevice();
                                    } else {
                                      _connectDevice(device: device);
                                    }
                                  },
                                );
                              }),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator());
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scaffoldMessenger({required String message, Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> addEtiquetaFila({required GlobalKey globalKey}) async {
    try {
      await impressorasController.enviaEtiqueta(key: globalKey);
    } catch (e) {
      _scaffoldMessenger(message: e.toString(), color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Etiquetas', style: TextStyle(fontSize: 20)),
          flexibleSpace: AppBarLinearGradientWidget(),
          actions: [
            PrinterStatusIconWidget(controller: impressorasController, onTap: _loadPrinters),
            IconButton(
              onPressed: _loadListaEtiquetas,
              icon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.refresh_outlined),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Obx(() {
                switch (etiquetaController.getState.value) {
                  case EtiquetaState.initial:
                    return const SizedBox();
                  case EtiquetaState.loading:
                    return const Center(child: CircularProgressIndicator());
                  case EtiquetaState.error:
                    return const Center(child: Text('Nenhuma etiqueta localizada!'));
                  case EtiquetaState.success:
                    return RefreshIndicator(
                      onRefresh: () async {
                        await _loadListaEtiquetas();
                      },
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        itemCount: _visible.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _visible.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                          final etiquetaModel = _visible[index];
                          final key = GlobalKey();
                          return impressorasController.getSizeLabelPrint.value == SizeLabelPrint.$50_x_50
                              ? Etiqueta50x50Widget(
                                  etiquetaModel: etiquetaModel,
                                  fgImprimir: true,
                                  globalKey: key,
                                  fn: () => addEtiquetaFila(globalKey: key),
                                  sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                                )
                              : EtiquetaWidget(
                                  etiquetaModel: etiquetaModel,
                                  fgImprimir: true,
                                  globalKey: key,
                                  fn: () => addEtiquetaFila(globalKey: key),
                                  sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                                );
                        },
                      ),
                    );
                }
              }),
            ),
            PrintingStatusOverlayWidget(controller: impressorasController),
          ],
        ),
      ),
    );
  }
}
