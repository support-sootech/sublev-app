
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/etiqueta_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_50x50_widget.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class EtiquetasPage extends StatefulWidget {
  const EtiquetasPage({super.key});

  @override
  State<EtiquetasPage> createState() => _EtiquetasPageState();
}

class _EtiquetasPageState extends State<EtiquetasPage> {
  final EtiquetaController etiquetaController = EtiquetaController();
  final NiimbotImpressorasController impressorasController =
      Get.find<NiimbotImpressorasController>();

  @override
  void initState() {
    super.initState();
    _loadListaEtiquetas();
  }

  _loadListaEtiquetas() async {
    try {
      await etiquetaController.loadListaEtiquetas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("${e.toString()}")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    etiquetaController.dispose();
    super.dispose();
  }

  Future<void> addEtiquetaFila({required GlobalKey globalKey}) async {
    debugPrint("INICIO IMPRESSÃO ETIQUETA: ${DateTime.now()}");
    try {
      // Removido snackbar antecipado: agora somente após validação de conexão dentro do controller
      await impressorasController.enviaEtiqueta(key: globalKey);
    } catch (e) {
      _scaffoldMessenger(message: "${e}", color: Colors.red);
    }
  }

  _setLayout({required SizeLabelPrint sizeLabelPrint}) {
    impressorasController.setSizeLabelPrint = sizeLabelPrint;
    setState(() {});
  }

  void _loadPrinters() async {
    bool isBluetoothEnabled = await impressorasController.isBluetoothEnabled();
    if (!isBluetoothEnabled) {
      _scaffoldMessenger(
        message: 'No seu aparelho não está ligado o Bluetooth!',
      );
      return;
    }
    await impressorasController.loadImpressoras();
    modalListaImpressoras();
  }

  void _connectDevice({required BluetoothDevice device}) async {
    await impressorasController.connectDevices(device: device);
  }

  void _disconnectDevice() async {
    await impressorasController.disconnectDevice();
  }

  modalListaImpressoras() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          title: Text(
            "Impressão",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            children: [
              Text(
                "Layout",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),

              Obx(() {
                return Row(
                  children: [
                    Row(
                      children: [
                        Radio(
                          activeColor: Colors.blue,
                          value: impressorasController.getSizeLabelPrint.value,
                          groupValue: SizeLabelPrint.$50_x_30,
                          onChanged: (value) {
                            debugPrint("VALUE: $value");
                            _setLayout(sizeLabelPrint: SizeLabelPrint.$50_x_30);
                          },
                        ),
                        Text("50 x 30"),
                      ],
                    ),
                    Row(
                      children: [
                        Radio(
                          activeColor: Colors.blue,
                          value: impressorasController.getSizeLabelPrint.value,
                          groupValue: SizeLabelPrint.$50_x_50,
                          onChanged: (value) {
                            debugPrint("VALUE: $value");
                            _setLayout(sizeLabelPrint: SizeLabelPrint.$50_x_50);
                          },
                        ),
                        Text("50 x 50"),
                      ],
                    ),
                  ],
                );
              }),

              /*
              Obx(() {
                return Column(
                  children: [
                    Text(
                      "Qualidade: ${impressorasController.getPixelRatio.value.toStringAsFixed(2)}",
                    ),
                    Slider(
                      value: impressorasController.getPixelRatio.value,
                      min: 1.0,
                      max: 7.99,
                      divisions:
                          699, // Para ir de 1.00 a 7.99, você tem 699 "passos" (799 - 100)
                      label: impressorasController.getPixelRatio.value
                          .toStringAsFixed(2),
                      onChanged: (double newValue) {
                        setState(() {
                          impressorasController.setPixelRatio = newValue;
                        });
                      },
                    ),
                  ],
                );
              }),
              */
              Text(
                "Lista de Impressoras",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),


              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.height * 0.8,
                child: Obx(
                  () =>
                      impressorasController.getStatusListaImpressoras.value ==
                          StatusListaImpressoras.success
                      ? ListView.builder(
                          itemCount:
                              impressorasController.getListaImpressoras.length,
                          itemBuilder: (BuildContext context, int index) {
                            BluetoothDevice device = impressorasController
                                .getListaImpressoras[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        "${device.name}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text("${device.address}"),
                                  ],
                                ),
                                Obx(() {
                                  final impressoraAtual = impressorasController
                                      .getImpressoraConectada.value;
                                  final conectado =
                                      impressoraAtual.address.isNotEmpty &&
                                          impressoraAtual.address ==
                                              device.address;
                                  return IconButton(
                                    onPressed: () {
                                      if (conectado) {
                                        _disconnectDevice();
                                      } else {
                                        _connectDevice(device: device);
                                      }
                                    },
                                    icon: Icon(
                                      conectado
                                          ? Icons.print_outlined
                                          : Icons.print_disabled_outlined,
                                      color: conectado ? Colors.green : Colors.red,
                                      size: 30,
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        )
                      : Center(child: CircularProgressIndicator()),
                ),
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

  // Função de teste de visualização removida (não utilizada)

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Lista de Etiquetas", style: TextStyle(fontSize: 20)),
          flexibleSpace: AppBarLinearGradientWidget(),
          actions: [
            IconButton(
              onPressed: () {
                _loadPrinters();
              },
              icon: Obx(
                () {
                  final state = impressorasController.getPrinterConnectionState.value;
                  final fila = impressorasController.getQtdFila.value;
                  if (state == PrinterConnectionState.disconnected) {
                    return const Icon(Icons.print_disabled_outlined, color: Colors.red);
                  }
                  if (state == PrinterConnectionState.connecting) {
                    return const Icon(Icons.sync, color: Colors.amber);
                  }
                  // connected: mostrar ícone de impressora e contador de fila
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.print_outlined, color: Colors.green),
                      if (fila > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              fila.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            IconButton(
              onPressed: () => _loadListaEtiquetas(),
              icon: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.refresh_outlined),
              ),
            ),
          ],
        ),
        body: Container(
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
                return const Center(child: Text("Nenhuma etiqueta localizada!"));
              case EtiquetaState.success:
                return ListView.builder(
                  itemCount: etiquetaController.getListaEtiquetdas.length,
                  itemBuilder: (BuildContext context, int index) {
                    EtiquetaModel etiquetaModel =
                        etiquetaController.getListaEtiquetdas[index];
                    GlobalKey globalKey = GlobalKey();
                    Widget wEtiqueta = impressorasController
                                .getSizeLabelPrint.value ==
                            SizeLabelPrint.$50_x_50
                        ? Etiqueta50x50Widget(
                            etiquetaModel: etiquetaModel,
                            fgImprimir: true,
                            globalKey: globalKey,
                            fn: () {
                              addEtiquetaFila(globalKey: globalKey);
                            },
                            sizeLabelPrint:
                                impressorasController.getSizeLabelPrint.value,
                          )
                        : EtiquetaWidget(
                            etiquetaModel: etiquetaModel,
                            fgImprimir: true,
                            globalKey: globalKey,
                            fn: () {
                              addEtiquetaFila(globalKey: globalKey);
                            },
                            sizeLabelPrint:
                                impressorasController.getSizeLabelPrint.value,
                          );
                    return wEtiqueta;
                  },
                );
            }
          }),
        ),
      ),
    );
  }
}
