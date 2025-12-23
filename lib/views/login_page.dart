import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/user_controller.dart';
import 'package:ootech/services/debug_log_service.dart';
import 'package:ootech/views/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKeyLogin = GlobalKey<FormState>();
  var userCpfController = TextEditingController();
  var userSenhaController = TextEditingController();
  final UserController userController = UserController();

  void showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Debug Logs (Production)"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              DebugLogService().getLogs().isEmpty 
                ? "Nenhum log capturado ainda." 
                : DebugLogService().getLogs(),
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: DebugLogService().getLogs()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Logs copiados!")),
              );
            },
            child: Text("Copiar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fechar"),
          ),
        ],
      ),
    );
  }

  void login() async {
    if (formKeyLogin.currentState?.validate() != null) {
      formKeyLogin.currentState?.save();

      try {
        await userController.login(
          cpf: userCpfController.text,
          senha: userSenhaController.text,
        );
        navigator(HomePage());
      } catch (e) {
        scaffoldMessenger(message: e.toString(), color: Colors.red);
      }
    } else {
      scaffoldMessenger(
        message: "Você deve preencher os campos CPF e SENHA!",
        color: Colors.red,
      );
    }
  }

  void navigator(Widget w) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => w),
    );
  }

  void scaffoldMessenger({required String message, Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onLongPress: () => showDebugLogs(),
              child: Image.asset("assets/logo.png"),
            ),

            Obx(
              () => userController.getState.value == UserState.loading
                  ? Center(child: CircularProgressIndicator())
                  : Form(
                      key: formKeyLogin,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: userCpfController,
                            decoration: const InputDecoration(
                              hintText: 'CPF',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'O campo e-mail é obrigatório!';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              if (newValue != null) {
                                userCpfController.text = newValue;
                              }
                            },
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: userSenhaController,
                            decoration: const InputDecoration(
                              hintText: 'Senha',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.password_outlined),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'O campo senha é obrigatório!';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              if (newValue != null) {
                                userSenhaController.text = newValue;
                              }
                            },
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ElevatedButton(
                              onPressed: () => login(),
                              child: Text('Acessar'),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
