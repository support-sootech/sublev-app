import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/config/menu_data.dart';
import 'package:ootech/controller/material_fracionado_vencimento_controller.dart';
import 'package:ootech/models/material_fracionado_vencimento_model.dart';
import 'package:ootech/models/menu_model.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/views/materiais_fracionados_vencimento_lista_page.dart';
import 'package:ootech/views/widgets/drawer_widget.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';
import 'package:ootech/views/widgets/home/card_info_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();
  late UserModel userModel = UserModel();

  final MenuData menuData = MenuData();
  late List<MenuModel> arrMenu = [];

  late MaterialFracionadoVencimentoController materialFracionadoVencimentoController =
      MaterialFracionadoVencimentoController();
  bool isLoadingMateriaisFracionadosVencimento = true;
  late MaterialFracionadoVencimentoModel materialFracionadoVencimentoModel;

  Future loadUser() async {
    userModel = await userSharedPreferencesRepository.getUserSharedPreferences();
    setState(() {});
  }

  Future loadMenu() async {
    arrMenu = await menuData.loadMenu();
    setState(() {});
  }

  Future loadMaterialFracionadoVencimento() async {
    isLoadingMateriaisFracionadosVencimento = true;
    setState(() {});
    materialFracionadoVencimentoModel =
        await materialFracionadoVencimentoController.loadMaterialFracionadoVencimento();
    setState(() => isLoadingMateriaisFracionadosVencimento = false);
  }

  navigatorMateriaisFracionadosVencimentoPage({required String filtro}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MateriaisFracionadosVencimentoListaPage(filtro: filtro),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    loadMenu();
    loadMaterialFracionadoVencimento();
  }

  MenuModel? _findMenuById(int id) {
    try {
      return arrMenu.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Card idêntico ao seu padrão de atalhos
  Widget _menuCard(MenuModel m) {
    return InkWell(
      onTap: () {
        if (m.page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => m.page!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Atalho "${m.title ?? 'Sem título'}" não configurado')),
          );
        }
      },
      child: Card(
        elevation: 8,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(m.icon ?? Icons.apps),
            FittedBox(child: Text(m.title ?? '')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4 atalhos rápidos = ids 1..4 do menu
    final quickIds = <int>{1, 2, 3, 4};
    final quickItems = <MenuModel>[
      if (_findMenuById(1) != null) _findMenuById(1)!,
      if (_findMenuById(2) != null) _findMenuById(2)!,
      if (_findMenuById(3) != null) _findMenuById(3)!,
      if (_findMenuById(4) != null) _findMenuById(4)!,
    ];

    // outros atalhos (se no futuro o menu crescer, ficam aqui)
    final outrosAtalhos =
        arrMenu.where((m) => !(quickIds.contains(m.id ?? -1))).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset("assets/logo.png", width: 100),
          centerTitle: true,
          flexibleSpace: AppBarLinearGradientWidget(),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 35,
                child: Text("Bem vindo(a), ${userModel.nmPessoa}"),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // --------- Atalhos rápidos (2x2 do próprio menu) ----------
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: const Text(
                          "Atalhos rápidos",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: quickItems.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) => _menuCard(quickItems[index]),
                      ),

                      const SizedBox(height: 8),

                      // --------- Outros atalhos (se houver) ----------
                      if (outrosAtalhos.isNotEmpty) ...[
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: const Text(
                            "Outros atalhos",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                          itemCount: outrosAtalhos.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => _menuCard(outrosAtalhos[index]),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // --------- Materiais Fracionados (inalterado) ----------
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            const Text(
                              "Materiais Fracionados",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            IconButton(
                              onPressed: () async {
                                loadMaterialFracionadoVencimento();
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CardInfoWidget(
                                  cardColor: Colors.red,
                                  icon: FontAwesomeIcons.fireFlameCurved,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemHoje ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Hoje",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                    filtro: AcaoMateriaisFracionadoVencimento
                                        .vencem_hoje
                                        .toStringAcao,
                                  ),
                                ),
                                CardInfoWidget(
                                  cardColor: Colors.orange,
                                  icon: Icons.report_problem_outlined,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemAmanha ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Amanhã",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                    filtro: AcaoMateriaisFracionadoVencimento
                                        .vencem_amanha
                                        .toStringAcao,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CardInfoWidget(
                                  cardColor: Colors.blue,
                                  icon: Icons.calendar_today_outlined,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemSemana ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Em 7 dias",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                    filtro: AcaoMateriaisFracionadoVencimento
                                        .vencem_semana
                                        .toStringAcao,
                                  ),
                                ),
                                CardInfoWidget(
                                  cardColor: Colors.green,
                                  icon: Icons.calendar_month_outlined,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemMais1Semana ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Acima de 7 dias",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                    filtro: AcaoMateriaisFracionadoVencimento
                                        .vencem_mais_1_semana
                                        .toStringAcao,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: DrawerWidget(userModel: userModel),
      ),
    );
  }
}
