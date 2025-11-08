import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ootech/app.dart';
import 'package:ootech/controller/impressoras_controller.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';

void main() {
  runApp(const App());
  WidgetsFlutterBinding.ensureInitialized(); // Garanta que os bindings do Flutter estejam inicializados
  Get.put(ImpressorasController(), permanent: true);
  Get.put(NiimbotImpressorasController(), permanent: true);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const App());
  });
}
