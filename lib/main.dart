import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ootech/app.dart';
import 'package:ootech/controller/entrada_materiais_controller.dart';
import 'package:ootech/controller/etiqueta_avulsa_controller.dart';
import 'package:ootech/controller/impressoras_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';

Future<void> main() async {
  final t0 = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  final tAfterBinding = DateTime.now();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final tAfterOrient = DateTime.now();

  Get.put(ImpressorasController(), permanent: true);
  Get.put(NiimbotImpressorasController(), permanent: true);
  Get.lazyPut(() => EntradaMateriaisController(), fenix: true);
  Get.lazyPut(() => EtiquetaAvulsaController(), fenix: true);
  final tAfterControllers = DateTime.now();

  if (const bool.fromEnvironment('ENABLE_STARTUP_LOGS', defaultValue: true)) {
    // ignore: avoid_print
    print('[STARTUP] binding=${tAfterBinding.difference(t0).inMilliseconds}ms orient=${tAfterOrient.difference(tAfterBinding).inMilliseconds}ms controllers=${tAfterControllers.difference(tAfterOrient).inMilliseconds}ms total=${tAfterControllers.difference(t0).inMilliseconds}ms');
  }

  runApp(const App());
}
