import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/controller/material_fracionado_vencimento_controller.dart';
import 'package:ootech/models/etiqueta_model.dart';
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
  late final MaterialFracionadoVencimentoController
      materialFracionadoVencimentoController =
      MaterialFracionadoVencimentoController();

  @override
  void initState() {
    super.initState();
    _loadListaEtiquetas();
  }

  Future<void> _loadListaEtiquetas() async {
    await materialFracionadoVencimentoController
        .listaMaterialFracionadoVencimento(filtro: widget.filtro);
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
              Text("Vencimento $subTitle", style: TextStyle(fontSize: 16)),
            ],
          ),
          centerTitle: true,
          flexibleSpace: AppBarLinearGradientWidget(),
        ),
        body: Container(
          padding: const EdgeInsets.all(8),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Obx(() {
            switch (materialFracionadoVencimentoController.getState.value) {
              case MaterialFracionadoVencimentoState.loading:
                return const Center(child: CircularProgressIndicator());
              case MaterialFracionadoVencimentoState.error:
                return const SizedBox();
              case MaterialFracionadoVencimentoState.success:
                final lista =
                    materialFracionadoVencimentoController.getListaEtiquetdas;
                if (lista.isEmpty) {
                  return const Center(
                    child: Text("Nenhum material fracionado localizado!!"),
                  );
                }
                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, index) {
                    final EtiquetaModel etiquetaModel = lista[index];
                    return EtiquetaWidget(
                      etiquetaModel: etiquetaModel,
                      fgImprimir: false,
                      globalKey: null,
                      sizeLabelPrint: SizeLabelPrint.$50_x_50,
                    );
                  },
                );
            }
          }),
        ),
      ),
    );
  }
}
