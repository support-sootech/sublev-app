import 'package:flutter/material.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/views/home_page.dart';
import 'package:ootech/views/login_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Controlador da animação
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // Define a animação de escala (de 0.2 até 1.0)
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Inicia a animação
    _controller.forward();

    load();
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera os recursos da animação
    super.dispose();
  }

  load() async {
    Widget page = LoginPage();
    bool isLogged = await UserSharedPreferencesRepository.isLogged();
    if (isLogged) {
      page = HomePage();
    }
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: ScaleTransition(
              scale: _animation,
              child: Image.asset('assets/logo.png', width: 280),
            ),
          ),
        ),
      ),
    );
  }
}
