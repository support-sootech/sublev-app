import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/niimbot_impressoras_controller.dart';

/// Widget reutilizável para exibir overlay de status de impressão.
/// Mensagens padronizadas:
/// - Conectando à impressora… (estado connecting)
/// - Enviando para impressão… (processando fila)
/// - Impressora conectada (feedback rápido opcional quando conectar sem fila)
class PrintingStatusOverlayWidget extends StatelessWidget {
  final NiimbotImpressorasController controller;
  final bool showConnectedHint; // se true mostra breve hint ao conectar sem fila.
  const PrintingStatusOverlayWidget({super.key, required this.controller, this.showConnectedHint = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connecting = controller.getPrinterConnectionState.value == PrinterConnectionState.connecting;
      final processing = controller.getIsProcessingQueue.value;
      final connected = controller.getPrinterConnectionState.value == PrinterConnectionState.connected;
      if (!connecting && !processing) {
        // Hint de conexão rápida (exibe por 1.2s) apenas se configurado.
        if (showConnectedHint && connected) {
          return Positioned(
            bottom: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Impressora conectada', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }
      final message = connecting ? 'Conectando à impressora…' : 'Enviando para impressão…';
      return Positioned.fill(
        child: Stack(
          children: [
            const ModalBarrier(color: Colors.black45, dismissible: false),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(message, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
