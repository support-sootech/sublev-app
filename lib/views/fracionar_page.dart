import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/material_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/models/material_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_50x50_widget.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:ootech/views/widgets/printer_status_icon_widget.dart';
import 'package:ootech/views/widgets/printing_status_overlay_widget.dart';

class FracionarPage extends StatefulWidget {
  const FracionarPage({super.key});

  @override
  State<FracionarPage> createState() => _FracionarPageState();
}

class _FracionarPageState extends State<FracionarPage> {
  final formKey = GlobalKey<FormState>();
  final codigoTextController = TextEditingController();
  final MaterialController materialController = MaterialController();
  final NiimbotImpressorasController impressorasController =
      Get.find<NiimbotImpressorasController>();
  String? scannedCode;
  int qtdUnidade = 1;
  int qtdFracao = 1;
  Widget? w;

  @override
  void initState() {
    super.initState();
    // Usa detalhe unificado (por enquanto scope all sem lista)
    materialController.fetchVencimentoDetalhe(scope: 'all', includeList: false);
  }

  buscarMaterial({required String codigo}) async {
    if (formKey.currentState?.validate() != null) {
      formKey.currentState?.save();
      try {
        if (codigoTextController.text.isNotEmpty) {
          FocusScope.of(context).requestFocus(FocusNode());
          await materialController.buscarMaterial(filtro: codigo);
        }
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Você deve informar o código")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  limparBusca() {
    codigoTextController.text = "";
    materialController.limparListaMaterial();
  }

  void _openScannerModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ScannerDialog(
          onCodeScanned: (String code) {
            setState(() {
              scannedCode = code;
              codigoTextController.text = code;
            });
            Navigator.of(context).pop();
            buscarMaterial(codigo: code);
          },
        );
      },
    );
  }

  _fracionar({
    required int idMaterial,
    required int qtd,
    required String tipo,
  }) async {
    try {
      List<EtiquetaModel> etiquetas = await materialController.fracionaMaterial(
        idMaterial: idMaterial,
        qtdFracionada: qtd,
        tipo: tipo,
      );

      for (var i = 0; i < etiquetas.length; i++) {
        EtiquetaModel etiquetaModel = etiquetas[i];
        GlobalKey key = GlobalKey();
        setState(() {
          w =
              impressorasController.getSizeLabelPrint.value ==
                  SizeLabelPrint.$50_x_50
              ? Etiqueta50x50Widget(
                  etiquetaModel: etiquetaModel,
                  fgImprimir: true,
                  globalKey: key,
                  sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                )
              : EtiquetaWidget(
                  etiquetaModel: etiquetaModel,
                  fgImprimir: true,
                  globalKey: key,
                  sizeLabelPrint: impressorasController.getSizeLabelPrint.value,
                );
        });

        await Future.delayed(Duration(seconds: 1), () async {
          debugPrint(
            "${DateTime.now()}: Fracionamento etiqueta: ${etiquetaModel.idEtiquetas}",
          );
          await impressorasController.enviaEtiqueta(key: key);
        });
      }

      _scaffoldMessenger(
        message:
            "Material fracionado com sucesso, caso a impressora não esteja conectada ou erro na impressara acessa a lista de etiquetas e reimprima a etiqueta!",
        color: Colors.green,
      );
      setState(() => codigoTextController.text = "");
    } catch (e) {
      _scaffoldMessenger(message: "ERRO: ${e.toString()}");
    }
  }

  _setLayout({required SizeLabelPrint sizeLabelPrint}) {
    impressorasController.setSizeLabelPrint = sizeLabelPrint;
    setState(() {});
  }

  _fracionarMaterial({required MaterialModel materialModel}) {
    showDialog(
      useSafeArea: false,
      fullscreenDialog: true,
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(
                materialModel.descricao!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _somaSubtraiUnidade(
                                materialModel: materialModel,
                                acao: 'SUBTRAIR',
                                setDialogState: setDialogState,
                              ),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              qtdUnidade.toString(),
                              style: TextStyle(fontSize: 26),
                            ),
                            IconButton(
                              onPressed: () => _somaSubtraiUnidade(
                                materialModel: materialModel,
                                acao: 'ADICIONAR',
                                setDialogState: setDialogState,
                              ),
                              icon: Icon(Icons.add_circle_outline_outlined),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _fracionar(
                            idMaterial: materialModel.idMateriais!,
                            qtd: qtdUnidade,
                            tipo: "UNIDADE",
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(80, 20),
                          padding: EdgeInsets.all(2),
                        ),
                        child: Text("Unidade", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _somaSubtraiFracao(
                                materialModel: materialModel,
                                acao: 'SUBTRAIR',
                                setDialogState: setDialogState,
                              ),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              qtdFracao.toString(),
                              style: TextStyle(fontSize: 26),
                            ),
                            IconButton(
                              onPressed: () => _somaSubtraiFracao(
                                materialModel: materialModel,
                                acao: 'ADICIONAR',
                                setDialogState: setDialogState,
                              ),
                              icon: Icon(Icons.add_circle_outline_outlined),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _fracionar(
                            idMaterial: materialModel.idMateriais!,
                            qtd: qtdFracao,
                            tipo: "FRACAO",
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(80, 20),
                          padding: EdgeInsets.all(2),
                        ),
                        child: Text(
                          "Fracionar",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              actions: [
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    label: Text("Fechar"),
                    icon: Icon(Icons.clear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => _resetValues());
  }

  _resetValues() {
    qtdFracao = 1;
    qtdUnidade = 1;
  }

  _somaSubtraiUnidade({
    required MaterialModel materialModel,
    required String acao,
    required Function? setDialogState,
  }) {
    if (acao == 'ADICIONAR') {
      if (qtdUnidade < materialModel.quantidade!) {
        qtdUnidade++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                "O limite máximo de unidades no estoque é de ${materialModel.quantidade}",
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (qtdUnidade > 1) {
        qtdUnidade = qtdUnidade - 1;
      }
    }
    setDialogState!(() {});
  }

  _somaSubtraiFracao({
    required MaterialModel materialModel,
    required String acao,
    required Function? setDialogState,
  }) {
    if (acao == 'ADICIONAR') {
      int limite = 20;
      if (qtdFracao < limite) {
        qtdFracao++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                "O limite máximo de unidades no estoque é de ${limite}",
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (qtdFracao > 1) {
        qtdFracao = qtdFracao - 1;
      }
    }
    setDialogState!(() {});
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
    debugPrint(
      "modalListaImpressoras: ${impressorasController.getImpressoraConectada.value.name}",
    );

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Fracionar Material", style: TextStyle(fontSize: 22)),
          flexibleSpace: AppBarLinearGradientWidget(),
          actions: [
            PrinterStatusIconWidget(controller: impressorasController, onTap: _loadPrinters),
            InkWell(
              onTap: () => limparBusca(),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.refresh_outlined),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: codigoTextController,
                          decoration: const InputDecoration(
                            hintText: 'Código ou Nome do Material',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'É necessário informar o código ou nome do material!';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            //codigoTextController.text = newValue!;
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await buscarMaterial(
                                  codigo: codigoTextController.text,
                                );
                              },
                              label: Text("Manual"),
                              icon: Icon(Icons.search_rounded),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _openScannerModal();
                              },
                              label: Text("Código"),
                              icon: FaIcon(FontAwesomeIcons.barcode),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Obx(
                    () =>
                        materialController.getState.value ==
                            MaterialBuscaState.success
                        ? Expanded(
                            child: SizedBox(
                              child: ListView.builder(
                                itemBuilder: (BuildContext context, int index) {
                                  MaterialModel materialModel =
                                      materialController
                                          .getListaMaterial[index];
                                  Color colorBorderCard;
                                  if (materialModel.colorDtVencimento ==
                                      'success') {
                                    colorBorderCard = Colors.green;
                                  } else if (materialModel.colorDtVencimento ==
                                      'primary') {
                                    colorBorderCard = Colors.blueAccent;
                                  } else {
                                    colorBorderCard = Colors.red;
                                  }
                                  return InkWell(
                                    onTap: () {
                                      _fracionarMaterial(
                                        materialModel: materialModel,
                                      );
                                    },
                                    child: Card(
                                      elevation: 8,
                                      color: Colors.grey[100],
                                      child: ClipPath(
                                        clipper: ShapeBorderClipper(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: colorBorderCard,
                                                width: 5,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${materialModel.descricao}",
                                                style: TextStyle(fontSize: 16),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text("${materialModel.marca}"),
                                              Text(
                                                "Estoque: ${materialModel.quantidade}",
                                              ),
                                              Text(
                                                "Vencimento: ${materialModel.dtVencimento}",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                itemCount:
                                    materialController.getListaMaterial.length,
                              ),
                            ),
                          )
                        : SizedBox(),
                  ),
                ],
              ),
            ),
            Obx(
              () =>
                  materialController.getState.value ==
                      MaterialBuscaState.loading
                  ? Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withValues(
                        alpha: 0.5,
                        red: 0,
                        green: 0,
                        blue: 0,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SizedBox(),
            ),

            // Overlay padronizado de impressão
            PrintingStatusOverlayWidget(controller: impressorasController),

            Positioned(
              left: -10000.0,
              top: -10000.0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: w != null ? Center(child: w) : SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerDialog extends StatefulWidget {
  final Function(String) onCodeScanned;

  const _ScannerDialog({required this.onCodeScanned});

  @override
  _ScannerDialogState createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<_ScannerDialog> {
  MobileScannerController? controller;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (hasScanned) return; // Evita múltiplas detecções

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          hasScanned = true;
        });
        widget.onCodeScanned(barcode.rawValue!);
      }
    }
  }

  void _closeScanner() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Scanner
              MobileScanner(controller: controller, onDetect: _onBarcodeDetect),

              // Overlay com instruções e controles
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.3,
                    blue: 0,
                    red: 0,
                    green: 0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Título
                    // Área de foco
                    Center(
                      child: Container(
                        width: 280,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Cantos do scanner
                            Positioned(
                              top: -1,
                              left: -1,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -1,
                              left: -1,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -1,
                              right: -1,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botão Fechar
                          ElevatedButton.icon(
                            onPressed: _closeScanner,
                            label: Text("Fechar"),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
