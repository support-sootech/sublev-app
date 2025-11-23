import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:permission_handler/permission_handler.dart';

class NiimbotPrintBluetoothThermalService {
  NiimbotPrintBluetoothThermalService() {
    _requestBluetoothPermissions();
  }

  // Densidade anterior (backup) que produzia preto mais forte.
  static const int _defaultDensity = 8; // faixa alvo solicitada (7..9) virtual acima do limite físico
  // Permite ajuste dinâmico sem recompilar (expor via setter futuramente se necessário)
  int _currentDensity = _defaultDensity;

  final NiimbotLabelPrinter _niimbotLabelPrinterPlugin = NiimbotLabelPrinter();

  Future<void> _requestBluetoothPermissions() async {
    await [
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

  // Conexão rápida: estabelece bluetooth e retorna imediatamente sem teste de impressão.
  // Usado para feedback visual instantâneo no ícone (estado verde), enquanto o warmup roda em background.
  Future<bool> connectDevicesQuick({
    required BluetoothDevice device,
  }) async {
    bool connected = await _niimbotLabelPrinterPlugin.connect(device);
    debugPrint("CONNECTDEVICES QUICK: $connected");
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

  Future<ui.Image> resizeImage(ui.Image image, double targetWidth, double targetHeight) async {
    // Mantido para casos específicos; uso normal agora envia imagem bruta.
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
    bool forceResize = false,
    int? overrideDensity,
    bool invertColor = false,
    bool highContrast = true,
    int contrastThreshold = 150,
    bool useDithering = true,
    double gammaCorrection = 0.75,
    int repeatPasses = 1,
    int interPassDelayMs = 120,
    bool overstrike = false,
    bool dilate = true,
    int dilationRadius = 1,
    int thresholdOffset = 10, // usado no baseThreshold (avgL - offset)
    bool simulateMultiPassForDensity = false, // quando false não duplica etiqueta física
  }) async {
    final bool connected = await _niimbotLabelPrinterPlugin.isConnected();
    if (!connected) throw CustomException(message: 'Impressora não conectada');
    try {
      final Map<String, dynamic> sizeMap = sizeLabelPrint.toSizeLabelPrintValues;
      ui.Image toSend = imageEtiqueta;
      if (forceResize) {
        toSend = await resizeImage(imageEtiqueta, sizeMap['width'], sizeMap['height']);
      }
      // Plugin exige buffer bruto RGBA (width*height*4). Recupera rawRgba.
      final ByteData? bd = await toSend.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return false;
      Uint8List bytes = bd.buffer.asUint8List();
      if (highContrast) {
        // Matriz Bayer 4x4 para dithering ordenado (valores 0..15)
        const List<List<int>> bayer4x4 = [
          [0, 8, 2, 10],
          [12, 4, 14, 6],
          [3, 11, 1, 9],
          [15, 7, 13, 5],
        ];
        // Calcula luminância média para threshold adaptativo base
        double sumL = 0;
        int count = 0;
        for (int i = 0; i < bytes.length; i += 4) {
          final int r = bytes[i];
          final int g = bytes[i + 1];
          final int b = bytes[i + 2];
          sumL += 0.299 * r + 0.587 * g + 0.114 * b;
          count++;
        }
        final avgL = sumL / count; // 0..255
        // Base mais agressiva: reduz 20 para aproximar pretos médios
        double baseThreshold = (avgL - thresholdOffset).clamp(90, contrastThreshold.toDouble());
        debugPrint('[PRINT][contraste] avgL=${avgL.toStringAsFixed(1)} baseThreshold=${baseThreshold.toStringAsFixed(1)}');
        // Percorre pixels
        final int width = toSend.width;
        final int height = toSend.height;
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int index = (y * width + x) * 4;
            int r = bytes[index];
            int g = bytes[index + 1];
            int b = bytes[index + 2];
            // Luminância
            double l = 0.299 * r + 0.587 * g + 0.114 * b; // 0..255
            // Normaliza e aplica correção gamma (<1 escurece tons médios)
            double ln = l / 255.0;
            ln = pow(ln, gammaCorrection).toDouble(); // 0..1
            double lg = ln * 255.0;
            double localThreshold = baseThreshold;
            if (useDithering) {
              final int mVal = bayer4x4[y % 4][x % 4]; // 0..15
              // Offset proporcional ao valor da matriz (dispersão suave)
              // Centro em 0: (mVal/15 - 0.5) * amplitude
              final double ditherOffset = ((mVal / 15.0) - 0.5) * 26.0; // amplitude ligeiramente maior
              localThreshold = (baseThreshold + ditherOffset).clamp(50, 200);
            }
            if (lg < localThreshold) {
              bytes[index] = 0;
              bytes[index + 1] = 0;
              bytes[index + 2] = 0;
            } else {
              bytes[index] = 255;
              bytes[index + 1] = 255;
              bytes[index + 2] = 255;
            }
          }
        }
        if (dilate) {
          // Dilation simples para engrossar traços pretos.
          final int width = toSend.width;
          final int height = toSend.height;
          final Uint8List original = Uint8List.fromList(bytes); // snapshot pós-binarização
          for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
              final int index = (y * width + x) * 4;
              if (original[index] == 0) continue; // já preto
              bool makeBlack = false;
              for (int dy = -dilationRadius; dy <= dilationRadius && !makeBlack; dy++) {
                final int ny = y + dy;
                if (ny < 0 || ny >= height) continue;
                for (int dx = -dilationRadius; dx <= dilationRadius && !makeBlack; dx++) {
                  final int nx = x + dx;
                  if (nx < 0 || nx >= width) continue;
                  final int nIdx = (ny * width + nx) * 4;
                  if (original[nIdx] == 0) {
                    makeBlack = true;
                  }
                }
              }
              if (makeBlack) {
                bytes[index] = 0;
                bytes[index + 1] = 0;
                bytes[index + 2] = 0;
              }
            }
          }
        }
      }
      final List<int> outBytes = bytes.toList();
      final requestedDensity = overrideDensity ?? _currentDensity;
      final int logicalDensity = requestedDensity.clamp(1, 9); // expansão lógica
      // Nunca envie pluginDensity > 5 — plugin nativo aceita 1..5.
      int pluginDensity = logicalDensity > 5 ? 5 : logicalDensity;
      final int extraPasses = simulateMultiPassForDensity && logicalDensity > 5 ? logicalDensity - 5 : 0; // só gera passes se flag ativa
      if (requestedDensity != logicalDensity) {
        debugPrint('[PRINT][ajuste] densidade solicitada=$requestedDensity normalizada=$logicalDensity (1..9)');
      }
      if (logicalDensity > 5) {
        debugPrint('[PRINT][aviso] densidade lógica acima de 5 (=$logicalDensity). Enviando pluginDensity=5 e usando $extraPasses pass(es) adicionais se simulateMultiPassForDensity=true.');
      }
      debugPrint('[PRINT] inicio etiqueta w=${toSend.width} h=${toSend.height} densidadeLogica=$logicalDensity densidadePlugin=$pluginDensity passesExtra=$extraPasses multiPass=${simulateMultiPassForDensity ? 'on' : 'off'} rgba=true resize=${forceResize ? 'sim' : 'nao'}');
      Map<String, dynamic> dadosImagem = {
        'bytes': outBytes,
        'width': toSend.width,
        'height': toSend.height,
        'rotate': false,
        'invertColor': invertColor,
        'density': pluginDensity,
        'labelType': 1,
      };
      final int totalPasses = repeatPasses + extraPasses; // se simulateMultiPassForDensity=false => apenas repeatPasses (normalmente 1)
      bool overallSuccess = true;
      for (int pass = 1; pass <= totalPasses; pass++) {
        // Ajuste adaptativo de threshold em passes subsequentes (overstrike) para escurecer ainda mais.
        if (overstrike && pass > 1 && highContrast) {
          // Escurece: transforma cinzas claras restantes em preto usando novo loop rápido.
          for (int i = 0; i < outBytes.length; i += 4) {
            // Se pixel é branco, probabilisticamente converte dependendo do pass.
            if (outBytes[i] == 255) {
              // Regra simples: a cada passe extra torna ~25% adicionais pretos.
              if ((i ~/ 4 + pass) % 4 < pass) {
                outBytes[i] = 0; outBytes[i + 1] = 0; outBytes[i + 2] = 0;
              }
            }
          }
        }
        bool passResult;
        try {
          passResult = await _niimbotLabelPrinterPlugin.send(PrintData.fromMap(dadosImagem));
        } catch (eSend) {
          // Já garantimos pluginDensity<=5 — em caso de erro apenas logamos e não tentamos valores inválidos.
          debugPrint('[PRINT][fallback] envio falhou densidade=$pluginDensity erro=$eSend');
          passResult = false;
        }
        debugPrint('[PRINT] fim etiqueta pass=$pass/$totalPasses sucesso=$passResult densidadeUsada=${dadosImagem['density']} overstrike=$overstrike');
        if (!passResult) overallSuccess = false;
        if (pass < totalPasses) {
          if (overstrike) {
            // Pequena redução no threshold para segundo(s) passe(s) escurecer ainda mais tons médios
            // (não recalcula toda a imagem; simples reenvio aumenta aquecimento)
          }
          await Future.delayed(Duration(milliseconds: interPassDelayMs));
        }
      }
      return overallSuccess;
    } catch (e) {
      debugPrint('[PRINT][erro] printEtiqueta: $e');
      return false;
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
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;
      final List<int> bytesImage = byteData.buffer.asUint8List().toList();

      Map<String, dynamic> datosImagen = {
        "bytes": bytesImage,
        "width": image.width,
        "height": image.height,
        "rotate": false,
        "invertColor": false,
        "density": _currentDensity,
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
      final requestedDensity = overrideDensity ?? _currentDensity;
      final int logicalDensity = requestedDensity.clamp(1, 9);
      // Nunca envie pluginDensity > 5 — plugin nativo aceita 1..5.
      int pluginDensity = logicalDensity > 5 ? 5 : logicalDensity;
      final int extraPasses = logicalDensity > 5 ? logicalDensity - 5 : 0;
      if (requestedDensity != logicalDensity) {
        debugPrint('[PRINT][ajuste] (logo) densidade solicitada=$requestedDensity normalizada=$logicalDensity');
      }
      if (logicalDensity > 5) {
        debugPrint('[PRINT][aviso] (logo) densidade lógica acima de 5 (=$logicalDensity). Enviando pluginDensity=5 e usando $extraPasses pass(es) adicionais.');
      }
      Map<String, dynamic> dadosImagem = {
        'bytes': outBytes,
        'width': image.width,
        'height': image.height,
        'rotate': false,
        'invertColor': false,
        'density': pluginDensity,
        'labelType': 1,
      };
      bool overallSuccess = true;
      final int totalPasses = 1 + extraPasses;
      for (int pass = 1; pass <= totalPasses; pass++) {
        bool passResult;
        try {
          passResult = await _niimbotLabelPrinterPlugin.send(PrintData.fromMap(dadosImagem));
        } catch (eSendLogo) {
          debugPrint('[PRINT][erro] (logo) envio falhou densidade=$pluginDensity: $eSendLogo');
          passResult = false;
        }
        debugPrint('[PRINT] teste logo pass=$pass/$totalPasses densidadeUsada=${dadosImagem['density']} sucesso=$passResult');
        if (!passResult) overallSuccess = false;
        if (pass < totalPasses) {
          await Future.delayed(const Duration(milliseconds: 120));
        }
      }
      final bool result = overallSuccess;
      return result;
    } catch (e) {
      debugPrint('[PRINT][erro] printTesteLogo: $e');
      return false;
    }
  }
}
