import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/material_fracionado_vencimento_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_50x50_widget.dart';
import 'package:ootech/views/widgets/etiqueta/etiqueta_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class MateriaisFracionadosVencimentoListaPage extends StatefulWidget {
  final String filtro;
  const MateriaisFracionadosVencimentoListaPage({
    super.key,
    required this.filtro,
  });

  @override
  State<MateriaisFracionadosVencimentoListaPage> createState() =>
      _MateriaisFracionadosVencimentoListaPageState();
}

class _MateriaisFracionadosVencimentoListaPageState
    extends State<MateriaisFracionadosVencimentoListaPage> {
  late MaterialFracionadoVencimentoController
  materialFracionadoVencimentoController =
      MaterialFracionadoVencimentoController();

  final NiimbotImpressorasController impressorasController =
      Get.find<NiimbotImpressorasController>();

  _loadListaEtiquetas() async {
    await materialFracionadoVencimentoController
        .listaMaterialFracionadoVencimento(filtro: widget.filtro);
  }

  @override
  void initState() {
    super.initState();
    _loadListaEtiquetas();
  }

  @override
  Widget build(BuildContext context) {
    String subTitle = '';

    if (AcaoMateriaisFracionadoVencimento.vencem_hoje.toStringAcao ==
        widget.filtro) {
      subTitle = "hoje";
    } else if (AcaoMateriaisFracionadoVencimento.vencem_amanha.toStringAcao ==
        widget.filtro) {
      subTitle = "amanhã";
    } else if (AcaoMateriaisFracionadoVencimento.vencem_semana.toStringAcao ==
        widget.filtro) {
      subTitle = "em 7 dias";
    } else {
      subTitle = "acima de 7 dias";
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text("Materiais Fracionados", style: TextStyle(fontSize: 24)),
              Text("Vencimento ${subTitle}", style: TextStyle(fontSize: 16)),
            ],
          ),
          centerTitle: true,
          flexibleSpace: AppBarLinearGradientWidget(),
        ),
        body: Container(
          padding: EdgeInsets.all(8),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Obx(() {
            Widget w = SizedBox();
            switch (materialFracionadoVencimentoController.getState.value) {
              case MaterialFracionadoVencimentoState.loading:
                w = Center(child: CircularProgressIndicator());
                break;
              case MaterialFracionadoVencimentoState.success:
                w =
                    materialFracionadoVencimentoController
                            .getListaEtiquetdas
                            .length >
                        0
                    ? ListView.builder(
                        itemCount: materialFracionadoVencimentoController
                            .getListaEtiquetdas
                            .length,
                        itemBuilder: (BuildContext context, int index) {
                          EtiquetaModel etiquetaModel =
                              materialFracionadoVencimentoController
                                  .getListaEtiquetdas[index];

                          return impressorasController
                                      .getSizeLabelPrint
                                      .value ==
                                  SizeLabelPrint.$50_x_50
                              ? Etiqueta50x50Widget(
                                  etiquetaModel: etiquetaModel,
                                  fgImprimir: true,
                                  globalKey: null,
                                  sizeLabelPrint: impressorasController
                                      .getSizeLabelPrint
                                      .value,
                                )
                              : EtiquetaWidget(
                                  etiquetaModel: etiquetaModel,
                                  fgImprimir: true,
                                  globalKey: null,
                                  sizeLabelPrint: impressorasController
                                      .getSizeLabelPrint
                                      .value,
                                );
                        },
                      )
                    : Center(
                        child: Text("Nenhum material fracionado localizado!!"),
                      );
                break;
              case MaterialFracionadoVencimentoState.error:
                w = SizedBox();
                break;
            }
            return w;
          }),
        ),
      ),
    );
  }
}
