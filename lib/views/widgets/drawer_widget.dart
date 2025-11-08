import 'package:flutter/material.dart';
import 'package:ootech/config/menu_data.dart';
import 'package:ootech/models/menu_model.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/views/login_page.dart';

class DrawerWidget extends StatefulWidget {
  final UserModel userModel;
  const DrawerWidget({super.key, required this.userModel});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  final MenuData menuData = MenuData();
  late List<MenuModel> arrMenu = [];

  @override
  void initState() {
    loadMenu();
    super.initState();
  }

  loadMenu() async {
    arrMenu = await menuData.loadMenu();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 80,
              padding: EdgeInsets.all(8),
              color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FittedBox(
                    child: Text(
                      widget.userModel.nmPessoa!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    icon: Icon(Icons.logout_outlined, semanticLabel: 'Logout'),
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: arrMenu.length,
                itemBuilder: (BuildContext context, int index) {
                  MenuModel menu = arrMenu[index];

                  return ListTile(
                    leading: Icon(menu.icon),
                    title: Text(menu.title!),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => menu.page!),
                      );
                    },
                  );
                },
              ),
            ),
            /*
            ListTile(
              leading: Icon(Icons.qr_code_2),
              title: Text('Consultar Produto'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.device_hub),
              title: Text('Fracionamento'),
              onTap: () {},
            ),
            */
          ],
        ),
      ),
    );
  }
}
