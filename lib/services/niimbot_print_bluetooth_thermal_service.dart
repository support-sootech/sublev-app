import 'dart:ui' as ui;
import 'dart:async';
// ...existing code...
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
// ...existing code...

class NiimbotPrintBluetoothThermalService {
      // Compatibilidade com controller
      Future<bool> isBbluetoothEnabled() async {
        // O plugin pode não expor diretamente, mas normalmente retorna true se conseguir escanear
        // Aqui, apenas retorna true para manter compatibilidade, ajuste conforme necessário
        return true;
      }

      Future<List<BluetoothDevice>> loadDevices() async {
        // Busca dispositivos pareados via plugin
        return await _niimbotLabelPrinterPlugin.getPairedDevices();
      }

      Future<bool> connectDevicesQuick({required BluetoothDevice device}) async {
        // Conecta rapidamente sem warmup
        return await _niimbotLabelPrinterPlugin.connect(device);
      }

      Future<bool> disconnectDevice() async {
        return await _niimbotLabelPrinterPlugin.disconnect();
      }
    // Redimensiona a imagem para o tamanho correto da etiqueta (igual main)
    Future<ui.Image> resizeImage(ui.Image image, double targetWidth, double targetHeight) async {
      debugPrint("INICIO RESIZE IMAGE: ${DateTime.now()}");
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();
      final scaleX = targetWidth / image.width;
      final scaleY = targetHeight / image.height;
      canvas.scale(scaleX, scaleY);
      canvas.drawImage(image, Offset.zero, paint);
      final resizedImage = await recorder.endRecording().toImage(targetWidth.toInt(), targetHeight.toInt());
      debugPrint("FINAL RESIZE IMAGE: ${DateTime.now()}");
      return resizedImage;
    }
  NiimbotPrintBluetoothThermalService();
  // Utilitário para carregar imagem de asset (igual main)
  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  // Densidade padrão (main branch)
  static const int _defaultDensity = 2;
  int _currentDensity = _defaultDensity;
  final NiimbotLabelPrinter _niimbotLabelPrinterPlugin = NiimbotLabelPrinter();
  Future<bool> printEtiqueta({
    required ui.Image imageEtiqueta,
    required SizeLabelPrint sizeLabelPrint,
    int? overrideDensity,
  }) async {
    try {
      debugPrint("INICIO FUNÇÃO IMPRESSÃO ETIQUETA: ${DateTime.now()}");
      final Map<String, dynamic> sizeMap = sizeLabelPrint.toSizeLabelPrintValues;
      debugPrint(
        "IMAGEM SIZE: ${sizeMap['width']} x ${sizeMap['height']}",
      );
      final ui.Image resizedImage = await resizeImage(
        imageEtiqueta,
        sizeMap['width'],
        sizeMap['height'],
      );
      final ByteData? byteData = await resizedImage.toByteData();
      if (byteData == null) return false;
      final List<int> bytesImage = byteData.buffer.asUint8List().toList();
      final int density = (overrideDensity ?? _currentDensity).clamp(1, 5);
      final Map<String, dynamic> dadosImagem = {
        'bytes': bytesImage,
        'width': resizedImage.width,
        'height': resizedImage.height,
        'rotate': false,
        'invertColor': false,
        'density': density,
        'labelType': 1,
      };
      final PrintData printData = PrintData.fromMap(dadosImagem);
      final bool result = await _niimbotLabelPrinterPlugin.send(printData);
      debugPrint("FINAL IMPRESSAO: ${DateTime.now()}");
      return result;
    } catch (e) {
      debugPrint("ERRO: $e");
      return false;
    }
  }


  Future<bool> printTesteLogo({int? overrideDensity}) async {
    final bool isConnected = await _niimbotLabelPrinterPlugin.isConnected();
    if (!isConnected) return false;
    try {
      final ui.Image image = await loadImage('assets/logo.png');
      final ByteData? bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return false;
      Uint8List bytes = bd.buffer.asUint8List();
      // Aplica binarização simples para reforçar contraste do logo
      for (int i = 0; i < bytes.length; i += 4) {
        final int r = bytes[i];
        final int g = bytes[i + 1];
        final int b = bytes[i + 2];
        final double l = 0.299 * r + 0.587 * g + 0.114 * b;
        if (l > 200) {
          bytes[i] = 255; bytes[i + 1] = 255; bytes[i + 2] = 255;
        } else {
          bytes[i] = 0; bytes[i + 1] = 0; bytes[i + 2] = 0;
        }
      }
      final List<int> outBytes = bytes.toList();
      final int requestedDensity = overrideDensity ?? _currentDensity;
      final int density = requestedDensity.clamp(1, 5);
      Map<String, dynamic> dadosImagem = {
        'bytes': outBytes,
        'width': image.width,
        'height': image.height,
        'rotate': false,
        'invertColor': false,
        'density': density,
        'labelType': 1,
      };
      final PrintData printData = PrintData.fromMap(dadosImagem);
      final bool result = await _niimbotLabelPrinterPlugin.send(printData);
      debugPrint('[PRINT][main] Teste logo enviada para plugin. Tamanho: ${image.width}x${image.height}, densidade: $density, resultado: $result');
      return result;
    } catch (e) {
      debugPrint('[PRINT][erro] printTesteLogo: $e');
      return false;
    }
  }
}

