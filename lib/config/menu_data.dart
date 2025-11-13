import 'package:flutter/material.dart';
import 'package:ootech/models/menu_model.dart';
import 'package:ootech/views/consulta_etiqueta_page.dart';
import 'package:ootech/views/etiquetas_page.dart';
import 'package:ootech/views/fracionar_page.dart';
// NOVO — criaremos no próximo passo
import 'package:ootech/views/etiqueta_avulsa_page.dart';

class MenuData {
  Future<List<MenuModel>> loadMenu() async {
    final List<MenuModel> menu = [];

    menu.add(
      MenuModel(
        id: 1,
        title: "Consultar",
        page: const ConsultaEtiquetaPage(),
        icon: Icons.search_outlined,
      ),
    );

    menu.add(
      MenuModel(
        id: 2,
        title: "Fracionar",
        page: const FracionarPage(),
        icon: Icons.device_hub,
      ),
    );

    menu.add(
      MenuModel(
        id: 3,
        title: "Visualizar Etiquetas", // renomeado
        page: const EtiquetasPage(),
        icon: Icons.print_outlined,
      ),
    );

    // NOVO item
    menu.add(
      MenuModel(
        id: 4,
        title: "Etiqueta avulsa",
        page: const EtiquetaAvulsaPage(), // página nova (será criada)
        icon: Icons.label_outline,
      ),
    );

    return menu;
  }
}
