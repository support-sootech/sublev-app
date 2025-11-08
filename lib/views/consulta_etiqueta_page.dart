import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ootech/controller/etiqueta_controller.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class ConsultaEtiquetaPage extends StatefulWidget {
  const ConsultaEtiquetaPage({super.key});

  @override
  State<ConsultaEtiquetaPage> createState() => _ConsultaEtiquetaPageState();
}

class _ConsultaEtiquetaPageState extends State<ConsultaEtiquetaPage> {
  final formKey = GlobalKey<FormState>();
  final codigoTextController = TextEditingController();
  final motivoDescarteTextController = TextEditingController();
  final EtiquetaController etiquetaController = EtiquetaController();

  String? scannedCode;

  _removeEtiqueta(EtiquetaModel etiquetaModel) async {
    await etiquetaController.removeEtiquetasLista(etiquetaModel);
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
            buscarEtiqueta(codigo: code);
          },
        );
      },
    );
  }

  buscarEtiqueta({
    required String codigo,
    bool fgOpenScannerModal = true,
  }) async {
    if (formKey.currentState?.validate() != null) {
      formKey.currentState?.save();
      try {
        if (codigoTextController.text.isNotEmpty) {
          FocusScope.of(context).requestFocus(FocusNode());
          await etiquetaController.loadEtiqueta(codigo: codigo);

          if (fgOpenScannerModal) {
            _openScannerModal();
          }
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

  modalEtiquetaInfo(EtiquetaModel etiquetaModel) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
            "${etiquetaModel.dsMaterial}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              fontSize: 16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        child: Text(
                          "Validade: ${etiquetaModel.dtVencimento}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          "Manipulação: ${etiquetaModel.dtFracionamento}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        child: Text(
                          "Setor: ${etiquetaModel.nmSetor}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          "Qtd.: ${etiquetaModel.qtdFracionada} ${etiquetaModel.dsUnidadesMedidas}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${etiquetaModel.dsModoConservacao}",
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Resp.: ${etiquetaModel.nmPessoaAbreviado}",
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      "${etiquetaModel.numEtiqueta}",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Center(child: Icon(Icons.qr_code_2_rounded, size: 46)),
                  Center(child: Image.asset("assets/logo.png", width: 50)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  _baixaDescarteEtiquetas({required String status}) {
    try {
      etiquetaController
          .baixaDescarteMaterialFracionado(
            status: status,
            motivo: motivoDescarteTextController.text,
          )
          .then((bool value) {
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      "Etiqueta(s) ${status == 'C' ? "baixada" : "descartada"}(s) com sucesso!",
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              motivoDescarteTextController.text = "";
            }
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  _baixarEtiquetasLista() async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          title: Text(
            "Baixar etiqueta(s)",
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Text(
              "Você tem certeza que deseja baixar as etiquetas?",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              label: Text("Não"),
              icon: Icon(Icons.cancel),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _baixaDescarteEtiquetas(status: 'V');
                Navigator.of(context).pop();
              },
              label: Text("Sim"),
              icon: Icon(Icons.check_circle),
            ),
          ],
        );
      },
    );
  }

  _descartarEtiquetasLista() async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          title: Text(
            "Descarte de etiqueta(s)",
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Você tem certeza que deseja descartar as etiquetas?",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: motivoDescarteTextController,
                  maxLength: 100,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Informe o motivo do descarte',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O campo motivo do descarte é obrigatório!';
                    }
                    return null;
                  },
                  onSaved: (newValue) {},
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              label: Text("Não"),
              icon: Icon(Icons.cancel),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (motivoDescarteTextController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          "É necessário informar o motivo do descarte!",
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  _baixaDescarteEtiquetas(status: 'D');
                  Navigator.of(context).pop();
                }
              },
              label: Text("Sim"),
              icon: Icon(Icons.check_circle),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Consulta de Etiqueta"),
          flexibleSpace: AppBarLinearGradientWidget(),
        ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
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
                            hintText: 'Código',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code_2_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'É necessário informar o código!';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            codigoTextController.text = newValue!;
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await buscarEtiqueta(
                                  codigo: codigoTextController.text,
                                  fgOpenScannerModal: false,
                                );
                              },
                              label: Text("Manual"),
                              icon: Icon(Icons.search_rounded),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _openScannerModal();
                              },
                              label: Text("QR Code"),
                              icon: Icon(Icons.camera_alt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Obx(
                        () => SingleChildScrollView(
                          child: ListView.builder(
                            itemCount: etiquetaController
                                .getListaEtiquetasSelecionadas
                                .length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              EtiquetaModel etiquetaModel = etiquetaController
                                  .getListaEtiquetasSelecionadas[index];
                              return InkWell(
                                onTap: () => modalEtiquetaInfo(etiquetaModel),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.qr_code_2_rounded),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${etiquetaModel.numEtiqueta}',
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${etiquetaModel.dsMaterial}',
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${etiquetaModel.dsModoConservacao}',
                                                  ),
                                                  Text(
                                                    '${etiquetaModel.qtdFracionada} ${etiquetaModel.dsUnidadesMedidas}',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeEtiqueta(etiquetaModel),
                                          icon: FaIcon(FontAwesomeIcons.trash),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () =>
                        etiquetaController
                                .getListaEtiquetasSelecionadas
                                .length >
                            0
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _baixarEtiquetasLista(),
                                  label: Text("Baixar"),
                                  icon: Icon(Icons.done, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                                Text(
                                  "${etiquetaController.getListaEtiquetasSelecionadas.length}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _descartarEtiquetasLista(),
                                  label: Text("Descartar"),
                                  icon: Icon(
                                    FontAwesomeIcons.trash,
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(),
                  ),
                ],
              ),
            ),
            Obx(
              () => etiquetaController.getState.value == EtiquetaState.loading
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
