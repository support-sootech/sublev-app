import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/material_controller.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class ConsultaMaterialPage extends StatefulWidget {
  const ConsultaMaterialPage({super.key});

  @override
  State<ConsultaMaterialPage> createState() => _ConsultaMaterialPageState();
}

class _ConsultaMaterialPageState extends State<ConsultaMaterialPage> {
  final formKey = GlobalKey<FormState>();
  final codigoTextController = TextEditingController();
  final MaterialController materialController = MaterialController();

  buscarMaterial({required String filtro}) async {
    if (formKey.currentState?.validate() != null) {
      formKey.currentState?.save();
      try {
        if (codigoTextController.text.isNotEmpty) {
          await materialController.buscarMaterial(filtro: filtro);
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Consulta de Produtos"),
          flexibleSpace: AppBarLinearGradientWidget(),
        ),
        body: Container(
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
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'É necessário informar o código ou nome do material!';
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
                            await buscarMaterial(
                              filtro: codigoTextController.text,
                            );
                          },
                          label: Text("Buscar"),
                          icon: Icon(Icons.search_rounded),
                        ),

                        ElevatedButton.icon(
                          onPressed: () {},
                          label: Text("QR Code"),
                          icon: Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Obx(() {
                Widget w = CircularProgressIndicator();
                switch (materialController.getState.value) {
                  case MaterialBuscaState.loading:
                    w = Center(child: CircularProgressIndicator());
                    break;
                  case MaterialBuscaState.initial:
                    w = SizedBox();
                    break;
                  case MaterialBuscaState.success:
                    w = SingleChildScrollView(
                      child: Container(
                        height: 20,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.orange,
                      ),
                    );
                  case MaterialBuscaState.error:
                    w = Center(child: Icon(Icons.error, size: 150));
                    break;
                }
                return w;
              }),
            ],
          ),
        ),
      ),
    );
  }
}
