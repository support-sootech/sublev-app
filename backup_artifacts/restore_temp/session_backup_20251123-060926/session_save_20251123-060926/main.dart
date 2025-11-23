import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ootech/app.dart';
import 'package:ootech/controller/impressoras_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';

Future<void> main() async {
  // Inicialize bindings antes de carregar variáveis de ambiente
  WidgetsFlutterBinding.ensureInitialized();

  // Tenta carregar .env.development automaticamente para ambiente de desenvolvimento.
  // Se o arquivo não existir, dotenv.load lançará uma exceção — usamos try/catch
  // para permitir fallback à resolução atual em `dio_custom.dart`.
  try {
    await dotenv.load(fileName: '.env.development');
  } catch (_) {
    // Ignore — manter comportamento atual se não houver arquivo de desenvolvimento.
  }

  // Registrar controllers permanentes
  Get.put(ImpressorasController(), permanent: true);
  Get.put(NiimbotImpressorasController(), permanent: true);

  // Forçar orientação e então iniciar a aplicação
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const App());
}
