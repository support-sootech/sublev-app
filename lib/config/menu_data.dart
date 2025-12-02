import 'package:flutter/material.dart';
import 'package:ootech/models/menu_model.dart';
import 'package:ootech/views/consulta_etiqueta_page.dart';
import 'package:ootech/views/etiqueta_avulsa_page.dart';
import 'package:ootech/views/etiquetas_page.dart';
import 'package:ootech/views/fracionar_page.dart';
import 'package:ootech/views/materiais_list_page.dart';
import 'package:ootech/views/relatorio_recebimento_page.dart';

class MenuData {
  Future<List<MenuModel>> loadMenu() async {
    List<MenuModel> menu = [];
    menu.add(
      MenuModel(
        id: 1,
        title: "Baixar/Descartar",
        page: ConsultaEtiquetaPage(),
        icon: Icons.save_alt,
      ),
    );
    menu.add(
      MenuModel(
        id: 2,
        title: "Fracionar",
        page: FracionarPage(),
        icon: Icons.device_hub,
      ),
    );

    menu.add(
      MenuModel(
        id: 3,
        title: "Visualizar Etiquetas",
        page: EtiquetasPage(),
        icon: Icons.search_outlined,
      ),
    );

    menu.add(
      MenuModel(
        id: 4,
        title: "Etiqueta avulsa",
        page: const EtiquetaAvulsaPage(),
        icon: Icons.label_outline,
      ),
    );

    menu.add(
      MenuModel(
        id: 5,
        title: "Entrada de Materiais",
        page: MateriaisListPage(),
        icon: Icons.input_outlined,
      ),
    );
    menu.add(
      MenuModel(
        id: 6,
        title: "Relat. Recebimento",
        page: const RelatorioRecebimentoPage(),
        icon: Icons.assignment_outlined,
      ),
    );

    return menu;
  }
}
