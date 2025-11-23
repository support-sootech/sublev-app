import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';

class NiimbotPrintBluetoothThermalService {
  NiimbotPrintBluetoothThermalService() {
    _requestBluetoothPermissions();
  }

  final NiimbotLabelPrinter _niimbotLabelPrinterPlugin = NiimbotLabelPrinter();

  Future<void> _requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    try {
      final bool result = await _niimbotLabelPrinterPlugin
          .requestPermissionGrant();
      debugPrint("_REQUESTBLUETOOTHPERMISSIONS: $result");
    } catch (e) {
      throw CustomException(message: "Permissões de Bluetooth negadas!");
    }
  }

  Future<bool> isBbluetoothEnabled() async {
    return await _niimbotLabelPrinterPlugin.bluetoothIsEnabled();
  }

  Future<List<BluetoothDevice>> loadDevices() async {
    final List<BluetoothDevice> result = await _niimbotLabelPrinterPlugin
        .getPairedDevices();

    return result;
  }

  Future<bool> connectDevices({
    required BluetoothDevice device,
    required SizeLabelPrint sizeLabelPrint,
  }) async {
    bool connected = await _niimbotLabelPrinterPlugin.connect(device);
    debugPrint("CONNECTDEVICES: $connected");

    if (connected) {
      try {
        // Aguarda um pequeno delay para estabilizar a conexão
        //await Future.delayed(Duration(milliseconds: 500));

        //bool testResult = await printTest(sizeLabelPrint: sizeLabelPrint);
        bool testResult = await printTesteLogo();
        debugPrint("PRINT TEST RESULT: $testResult");

        if (!testResult) {
          debugPrint("AVISO: Impressão de teste falhou");
        }
      } catch (e) {
        debugPrint("ERRO na impressão de teste: $e");
        // Não falha a conexão se o teste falhar
      }
    }

    return connected;
  }

  Future<bool> disconnectDevice() async {
    return await _niimbotLabelPrinterPlugin.disconnect();
  }

  Future<bool> isConnected() async {
    return await _niimbotLabelPrinterPlugin.isConnected();
  }

  Future<ui.Image> loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final Uint8List bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      //print("Image loaded, size: ${img.width}x${img.height}");
      completer.complete(img);
    });

    return completer.future;
  }

  Future<ui.Image> resizeImage(
    ui.Image image,
    double targetWidth,
    double targetHeight,
  ) async {
    debugPrint("INICIO RESIZE IMAGE: ${DateTime.now()}");
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Escala la imagen
    final paint = Paint();
    final scaleX = targetWidth / image.width;
    final scaleY = targetHeight / image.height;

    canvas.scale(scaleX, scaleY);
    canvas.drawImage(image, Offset.zero, paint);

    final resizedImage = await recorder.endRecording().toImage(
      targetWidth.toInt(),
      targetHeight.toInt(),
    );
    debugPrint("FINAL RESIZE IMAGE: ${DateTime.now()}");
    return resizedImage;
  }

  Future printEtiqueta({
    required ui.Image imageEtiqueta,
    required SizeLabelPrint sizeLabelPrint,
  }) async {
    try {
      debugPrint("INICIO FUNÇÃO IMPRESSÃO ETIQUETA: ${DateTime.now()}");
      //ui.Image image = await resizeImage(imageEtiqueta, 390, 250);
      Map<String, dynamic> sizelImagen = sizeLabelPrint.toSizeLabelPrintValues;
      debugPrint(
        "IMAGEM SIZE: ${sizelImagen['width']} x ${sizelImagen['height']}",
      );
      ui.Image image = await resizeImage(
        imageEtiqueta,
        sizelImagen['width'],
        sizelImagen['height'],
      );

      ByteData? byteData = await image.toByteData();
      List<int> bytesImage = byteData!.buffer.asUint8List().toList();
      Map<String, dynamic> datosImagen = {
        "bytes": bytesImage,
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": 2,
        "labelType": 1,
      };
      PrintData printData = PrintData.fromMap(datosImagen);
      final bool result = await _niimbotLabelPrinterPlugin.send(printData);
      debugPrint("FINAL IMPRESSAO: ${DateTime.now()}");
      return result;
    } catch (e) {
      debugPrint("ERRO: ${e}");
    }
  }

  Future<bool> printTest({required SizeLabelPrint sizeLabelPrint}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      Map<String, dynamic> sizelImagen = sizeLabelPrint.toSizeLabelPrintValues;
      debugPrint("TESTE: ${sizelImagen['width']} x ${sizelImagen['height']}}");
      //final int width = sizelImagen['width'].toInt();
      //final int height = sizelImagen['height'].toInt();

      final int width = 200;
      final int height = 140;

      // Desenha um fundo branco
      canvas.drawColor(Colors.white, BlendMode.srcOver);

      // Adiciona algumas linhas de teste para melhor calibração
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Desenha bordas para ajudar na calibração
      canvas.drawRect(
        Rect.fromLTWH(10, 10, width - 20.0, height - 20.0),
        paint,
      );

      // Adiciona texto de teste
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'TESTE',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );

      // Crie a imagem a partir do recorder
      final ui.Image image = await recorder.endRecording().toImage(
        width,
        height,
      );

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      List<int> bytesImage = byteData!.buffer.asUint8List().toList();

      Map<String, dynamic> datosImagen = {
        "bytes": bytesImage,
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": 2, // ← Mudança: usar mesma densidade da impressão normal
        "labelType": 1,
      };

      PrintData printData = PrintData.fromMap(datosImagen);
      final bool result = await _niimbotLabelPrinterPlugin.send(printData);

      return result;
    } catch (e) {
      debugPrint("ERRO na impressão de teste: $e");
      return false;
    }
  }

  Future<bool> printTesteLogo() async {
    final bool isConnected = await _niimbotLabelPrinterPlugin.isConnected();
    if (!isConnected) {
      debugPrint("Não Conectado!");
      return false;
    }

    ui.Image image = await loadImage('assets/logo.png');

    ByteData? byteData = await image.toByteData();
    List<int> bytesImage = byteData!.buffer.asUint8List().toList();
    Map<String, dynamic> dadosImagem = {
      "bytes": bytesImage,
      "width": image.width,
      "height": image.height,
      "rotate": false,
      "invertColor": false,
      "density": 1,
      "labelType": 1,
    };
    PrintData printData = PrintData.fromMap(dadosImagem);
    final bool result = await _niimbotLabelPrinterPlugin.send(printData);
    debugPrint("Teste impresso com sucesso!");

    return result;
  }
}
