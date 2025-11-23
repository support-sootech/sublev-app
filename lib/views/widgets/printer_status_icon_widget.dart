import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';

class PrinterStatusIconWidget extends StatelessWidget {
  final NiimbotImpressorasController controller;
  final VoidCallback onTap;
  const PrinterStatusIconWidget({super.key, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.getPrinterConnectionState.value;
      final fila = controller.getQtdFila.value;
      Widget icon;
      if (state == PrinterConnectionState.disconnected) {
        icon = const Icon(Icons.print_disabled_outlined, color: Colors.red);
      } else if (state == PrinterConnectionState.connecting) {
        icon = const Icon(Icons.sync, color: Colors.amber);
      } else {
        icon = Row(
          children: [
            const Icon(Icons.print_outlined, color: Colors.green),
            if (fila > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fila.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      }
      return InkWell(onTap: onTap, child: icon);
    });
  }
}
