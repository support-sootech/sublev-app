import 'package:flutter/material.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Etiqueta50x50Widget extends StatelessWidget {
  final EtiquetaModel etiquetaModel;
  final Function? fn;
  final bool fgImprimir;
  final GlobalKey? globalKey;
  final SizeLabelPrint sizeLabelPrint;
  final Function? fnTeste;

  const Etiqueta50x50Widget({
    super.key,
    required this.etiquetaModel,
    this.fn,
    required this.fgImprimir,
    this.globalKey,
    required this.sizeLabelPrint,
    this.fnTeste,
  });

  @override
  Widget build(BuildContext context) {
    final largura =
        (sizeLabelPrint.toSizeLabelPrintValues['width'] ?? 0).toDouble();
    final altura =
        (sizeLabelPrint.toSizeLabelPrintValues['height'] ?? 0).toDouble();

    Widget card = Card(
      color: Colors.grey[200],
      elevation: 8,
      child: Column(
        children: [
          RepaintBoundary(
            key: globalKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "${etiquetaModel.descricao}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Validade:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.dtVencimento}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Manipulado:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.dtFracionamento}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Qtd.:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.qtdFracionada} ${etiquetaModel.dsUnidadesMedidas}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Conservação:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.dsModoConservacao}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Setor:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.nmSetor}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Resp.:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${etiquetaModel.nmPessoaAbreviado}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        "sublev",
                        style: TextStyle(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${etiquetaModel.numEtiqueta}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          QrImageView(
                            data: etiquetaModel.numEtiqueta.toString(),
                            version: QrVersions.auto,
                            size: 80.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 120,
              child: fgImprimir
                  ? ElevatedButton(
                      onPressed: () async {
                        if (fn != null) {
                          fn!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(2),
                        backgroundColor: Colors.grey,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.qr_code_2_outlined),
                          SizedBox(width: 8),
                          Text("Imprimir", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
          if (fnTeste != null)
            Center(
              child: SizedBox(
                width: 120,
                child: fgImprimir
                    ? ElevatedButton(
                        onPressed: () async {
                          if (fnTeste != null) {
                            fnTeste!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(2),
                          backgroundColor: Colors.grey,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.qr_code_2_outlined),
                            SizedBox(width: 8),
                            Text("Teste", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
        ],
      ),
    );

    if (fgImprimir) {
      return card;
    }

    return SizedBox(width: largura, height: altura, child: card);
  }
}
