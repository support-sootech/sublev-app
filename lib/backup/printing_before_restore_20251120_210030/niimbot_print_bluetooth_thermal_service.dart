import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:permission_handler/permission_handler.dart';

class NiimbotPrintBluetoothThermalService {
  NiimbotPrintBluetoothThermalService() {
    // Solicita permissões Bluetooth necessárias para escanear e conectar
    _requestBluetoothPermissions();
  }

  // Densidade padrão (mantemos apenas este ajuste básico)
  static const int _defaultDensity = 9;

  final NiimbotLabelPrinter _niimbotLabelPrinterPlugin = NiimbotLabelPrinter();

  Future<void> _requestBluetoothPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    try {
      final bool result = await _niimbotLabelPrinterPlugin.requestPermissionGrant();
      debugPrint("[NIIMBOT] Permissões bluetooth concedidas: $result");
    } catch (e) {
      throw CustomException(message: "Permissões de Bluetooth negadas!");
    }
  }

  Future<bool> isBluetoothEnabled() async {
    return await _niimbotLabelPrinterPlugin.bluetoothIsEnabled();
  }

  Future<List<BluetoothDevice>> loadDevices() async {
    return await _niimbotLabelPrinterPlugin.getPairedDevices();
  }

  Future<bool> connectDevices({
    required BluetoothDevice device,
    required SizeLabelPrint sizeLabelPrint,
  }) async {
    bool conectado = await _niimbotLabelPrinterPlugin.connect(device);
    debugPrint("[NIIMBOT] Conectar dispositivo: $conectado");
    return conectado && await _niimbotLabelPrinterPlugin.isConnected();
  }

  Future<bool> disconnectDevice() async {
    return await _niimbotLabelPrinterPlugin.disconnect();
  }

  Future<bool> isConnected() async {
    return await _niimbotLabelPrinterPlugin.isConnected();
  }

  Future<ui.Image> loadImage(String asset) async {
    // Carrega imagem de assets e decodifica para ui.Image
    final ByteData data = await rootBundle.load(asset);
    final Uint8List bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }

  Future<ui.Image> resizeImage(ui.Image image, double targetWidth, double targetHeight) async {
    // Redimensiona a imagem para a área alvo e aplica fundo branco
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, targetWidth, targetHeight),
      Paint()..color = Colors.white,
    );
    final scaleX = targetWidth / image.width;
    final scaleY = targetHeight / image.height;
    canvas.scale(scaleX, scaleY);
    canvas.drawImage(image, Offset.zero, Paint());
    return await recorder.endRecording().toImage(targetWidth.toInt(), targetHeight.toInt());
  }

  Future<bool> printEtiqueta({
    required ui.Image imageEtiqueta,
    required SizeLabelPrint sizeLabelPrint,
  }) async {
    // Removido uso de timestamp detalhado; mantemos lógica simples.
    final bool connected = await _niimbotLabelPrinterPlugin.isConnected();
    if (!connected) throw CustomException(message: 'Impressora não conectada');
    try {
      final sizeMap = sizeLabelPrint.toSizeLabelPrintValues;
      debugPrint('[NIIMBOT] Dimensão capturada=${imageEtiqueta.width}x${imageEtiqueta.height} cfgModelo=${sizeMap['width']}x${sizeMap['height']}');
      // Envia imagem capturada diretamente (sem redimensionar nem binarizar)
      ByteData? bd = await imageEtiqueta.toByteData();
      if (bd == null) return false;
      List<int> bytes = bd.buffer.asUint8List().toList();
      debugPrint('[NIIMBOT] Bytes length=${bytes.length} (esperado w*h*4 ~ ${imageEtiqueta.width * imageEtiqueta.height * 4})');
      final dadosImagem = {
        'bytes': bytes,
        'width': imageEtiqueta.width,
        'height': imageEtiqueta.height,
        'rotate': false,
        'invertColor': false, // mantendo sem inversão
        'density': _defaultDensity,
        'labelType': 1,
      };
      final bool result = await _niimbotLabelPrinterPlugin.send(PrintData.fromMap(dadosImagem));
      debugPrint('[NIIMBOT] Resultado envio=$result');
      return result;
    } catch (e) {
      debugPrint('[NIIMBOT][DIAG] Exceção printEtiqueta: $e');
      return false;
    }
  }

  Future<bool> printTest({required SizeLabelPrint sizeLabelPrint}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const int width = 200;
      const int height = 140;
      canvas.drawColor(Colors.white, BlendMode.srcOver);
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      // Desenha retângulo de borda
      canvas.drawRect(Rect.fromLTWH(10, 10, width - 20.0, height - 20.0), paint);
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'TESTE',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // Centraliza texto
      textPainter.paint(canvas, Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2));
      final ui.Image image = await recorder.endRecording().toImage(width, height);
      ByteData? byteData = await image.toByteData();
      if (byteData == null) return false;
      List<int> bytesImage = byteData.buffer.asUint8List().toList();
      Map<String, dynamic> dadosImagem = {
        "bytes": bytesImage,
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": _defaultDensity,
        "labelType": 1,
      };
      PrintData printData = PrintData.fromMap(dadosImagem);
      return await _niimbotLabelPrinterPlugin.send(printData);
    } catch (e) {
      debugPrint("[NIIMBOT] Erro na impressão de teste: $e");
      return false;
    }
  }

  Future<bool> printTesteLogo() async {
    final bool isConnected = await _niimbotLabelPrinterPlugin.isConnected();
    if (!isConnected) return false;
    ui.Image image = await loadImage('assets/logo.png');
    ByteData? byteData = await image.toByteData();
    if (byteData == null) return false;
    List<int> bytesImage = byteData.buffer.asUint8List().toList();
    Map<String, dynamic> dadosImagem = {
      "bytes": bytesImage,
      "width": image.width,
      "height": image.height,
      "rotate": false,
      "invertColor": false,
      "density": _defaultDensity,
      "labelType": 1,
    };
    PrintData printData = PrintData.fromMap(dadosImagem);
    return await _niimbotLabelPrinterPlugin.send(printData);
  }

  // Etiqueta de warmup: pequeno quadrado preto para ativar cabeça térmica
  Future<bool> printWarmupHead() async {
    // Desativado: warmup removido para evitar página inicial em branco
    return true;
  }
}
// Fim do serviço de impressão Bluetooth Niimbot
