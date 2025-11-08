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

  late MaterialFracionadoVencimentoController
  materialFracionadoVencimentoController =
      MaterialFracionadoVencimentoController();
  bool isLoadingMateriaisFracionadosVencimento = true;
  late MaterialFracionadoVencimentoModel materialFracionadoVencimentoModel;

  Future loadUser() async {
    userModel = await userSharedPreferencesRepository
        .getUserSharedPreferences();
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
        await materialFracionadoVencimentoController
            .loadMaterialFracionadoVencimento();
    setState(() => isLoadingMateriaisFracionadosVencimento = false);
  }

  navigatorMateriaisFracionadosVencimentoPage({required String filtro}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MateriaisFracionadosVencimentoListaPage(filtro: filtro),
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

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.all(8),
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
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Text(
                          "Atalhos rápidos",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      SizedBox(height: 8),
                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemCount: arrMenu.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          MenuModel menuModel = arrMenu[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => menuModel.page!,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 8,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(menuModel.icon),
                                  FittedBox(child: Text(menuModel.title!)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Text(
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
                              icon: Icon(Icons.refresh),
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
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemHoje ?? 0}",
                                          style: TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Hoje",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                        filtro:
                                            AcaoMateriaisFracionadoVencimento
                                                .vencem_hoje
                                                .toStringAcao,
                                      ),
                                ),
                                CardInfoWidget(
                                  cardColor: Colors.orange,
                                  icon: Icons.report_problem_outlined,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemAmanha ?? 0}",
                                          style: TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Amanhã",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                        filtro:
                                            AcaoMateriaisFracionadoVencimento
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
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemSemana ?? 0}",
                                          style: TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Em 7 dias",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                        filtro:
                                            AcaoMateriaisFracionadoVencimento
                                                .vencem_semana
                                                .toStringAcao,
                                      ),
                                ),
                                CardInfoWidget(
                                  cardColor: Colors.green,
                                  icon: Icons.calendar_month_outlined,
                                  qtd: isLoadingMateriaisFracionadosVencimento
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          "${materialFracionadoVencimentoModel.vencemMais1Semana ?? 0}",
                                          style: TextStyle(
                                            fontSize: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                  descricao: "Acima de 7 dias",
                                  onTap: () =>
                                      navigatorMateriaisFracionadosVencimentoPage(
                                        filtro:
                                            AcaoMateriaisFracionadoVencimento
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
