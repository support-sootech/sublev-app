import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'dart:async';

class PrintBluetoothThermalService {
  PrintBluetoothThermalService() {
    _requestBluetoothPermissions();
  }

  bool connected = false;
  List<BluetoothInfo> items = [];

  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  Map<String, String> devices = {};

  Future<void> _requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true) {
      debugPrint("Permissões Bluetooth concedidas.");
      //connectDevice();
    } else {
      debugPrint("Permissões Bluetooth negadas.");
    }
  }

  Future<bool> isBbluetoothEnabled() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<bool> connectDevices({required String mac}) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: mac);
  }

  Future<List<Map<String, dynamic>>> loadDevices() async {
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    final List<Map<String, dynamic>> bluetoothDevicesData = listResult.map((
      BluetoothInfo bluetooth,
    ) {
      return {'name': bluetooth.name, 'mac': bluetooth.macAdress};
    }).toList();

    return bluetoothDevicesData;
  }

  Future<void> loadDevice() async {
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    final List<Map<String, String>> bluetoothDevicesData = listResult.map((
      BluetoothInfo bluetooth,
    ) {
      return {'name': bluetooth.name, 'mac': bluetooth.macAdress};
    }).toList();

    devices = bluetoothDevicesData[0];
  }

  Future<bool> connectDevice() async {
    await loadDevice();
    return await PrintBluetoothThermal.connect(
      macPrinterAddress: devices["mac"]!,
    );
  }

  Future<bool> disconnectDevice() async {
    return await PrintBluetoothThermal.disconnect;
  }

  Future<void> printTeste() async {
    bool isConnected = await connectDevice();
    debugPrint("isConnected: ${isConnected.toString()}");
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    debugPrint("TESTE ${conexionStatus.toString()}");

    if (conexionStatus) {
      String enter = '\n';
      await PrintBluetoothThermal.writeBytes(enter.codeUnits);
      //size of 1-5
      String text = "Hello $enter";
      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 1, text: "$text size 1"),
      );
      /*
      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 2, text: text + " size 2"),
      );
      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 3, text: text + " size 3"),
      );
      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 2, text: text + " size 4"),
      );
      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 3, text: text + " size 5"),
      );
      */
    } else {
      debugPrint("the printer is disconnected ($conexionStatus)");
    }
  }

  Future<void> imprimirEtiquetaCut() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conexionStatus) {
      List<int> bytes = [];
      // Using default profile
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      bytes += generator.reset();

      bytes += generator.cut();

      //bytes += generator.reset();
      // Enviar dados para impressora
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }

  /// Imprime etiqueta em impressora térmica ESC/POS (não Niimbot).
  /// [highContrast]: aplica binarização agressiva na logo.
  Future<void> imprimirEtiqueta({required EtiquetaModel etiqueta, bool highContrast = true}) async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;

    if (conexionStatus) {
      List<int> bytes = [];
      // Using default profile
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      bytes += generator.reset();

      // Título mais destacado (duplo altura) para ganhar densidade de pontos
      bytes += generator.text(
        removerAcentuacoes("${etiqueta.descricao}"),
        styles: PosStyles(
          bold: true,
          codeTable: 'CP437',
          fontType: PosFontType.fontA,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          align: PosAlign.center,
          underline: true,
        ),
      );
      //bytes += generator.hr(ch: '_', len: 32);

      bytes += generator.row([
        PosColumn(
          text: 'Val:${etiqueta.dtVencimentoReduzido}',
          width: 6,
          styles: PosStyles(
            align: PosAlign.left,
            bold: true,
            fontType: PosFontType.fontA,
          ),
        ),
        PosColumn(
          text: 'Man:${etiqueta.dtFracionamentoReduzido}',
          width: 6,
          styles: PosStyles(
            align: PosAlign.right,
            bold: true,
            fontType: PosFontType.fontA,
          ),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          text: 'Setor: ${etiqueta.nmSetor}',
          width: 9,
          styles: PosStyles(
            align: PosAlign.left,
            bold: true,
            fontType: PosFontType.fontA,
          ),
        ),
        PosColumn(
          text: 'Qtd: ${etiqueta.qtdFracionada}',
          width: 3,
          styles: PosStyles(
            align: PosAlign.right,
            bold: true,
            fontType: PosFontType.fontA,
          ),
        ),
      ]);

      bytes += generator.text(
        '${etiqueta.dsModoConservacao}',
        styles: PosStyles(fontType: PosFontType.fontA, bold: true),
      );

      bytes += generator.text(
        'Resp: ${etiqueta.nmPessoaAbreviado}',
        styles: PosStyles(fontType: PosFontType.fontA, bold: true),
      );
      //bytes += generator.feed(0);

      bytes += generator.text(
        '${etiqueta.idEtiquetas}',
        styles: PosStyles(fontType: PosFontType.fontA, bold: true, align: PosAlign.center),
      );

      // QR Code - verificação e limpeza da string
      bytes += generator.qrcode(
        "${etiqueta.idEtiquetas.toString().trim()}",
        align: PosAlign.center,
        size: QRSize.Size4,
      );

      try {
        final ByteData data = await rootBundle.load('assets/logo.png');
        final Uint8List bytesImg = data.buffer.asUint8List();
        // Decodificar a imagem
        img.Image? originalImage = img.decodeImage(bytesImg);

        if (originalImage != null) {
          // Redimensionar a imagem para otimizar a impressão (largura máxima para 58mm)
          // Para impressora de 58mm, largura máxima recomendada é cerca de 384 pixels
          img.Image resizedImage = img.copyResize(originalImage, width: 75);
          // Converter para escala de cinza para melhor qualidade na impressão térmica
          img.Image grayscaleImage = img.grayscale(resizedImage);
          if (highContrast) {
            // Binariza a imagem: preto/branco com threshold adaptativo
            int sum = 0;
            for (int y = 0; y < grayscaleImage.height; y++) {
              for (int x = 0; x < grayscaleImage.width; x++) {
                final p = grayscaleImage.getPixel(x, y);
                sum += img.getRed(p);
              }
            }
            final avg = sum / (grayscaleImage.width * grayscaleImage.height);
            final thresh = (avg - 25).clamp(60, 160); // agressivo para escurecer
            for (int y = 0; y < grayscaleImage.height; y++) {
              for (int x = 0; x < grayscaleImage.width; x++) {
                final p = grayscaleImage.getPixel(x, y);
                final l = img.getRed(p);
                if (l < thresh) {
                  grayscaleImage.setPixelRgba(x, y, 0, 0, 0, 255);
                } else {
                  grayscaleImage.setPixelRgba(x, y, 255, 255, 255, 255);
                }
              }
            }
          }
          // Garantir fallback seguro: se imagem ficou toda branca/preta, logar
          int black = 0, white = 0;
          for (int y = 0; y < grayscaleImage.height; y++) {
            for (int x = 0; x < grayscaleImage.width; x++) {
              final p = grayscaleImage.getPixel(x, y);
              if (img.getRed(p) == 0) black++; else white++;
            }
          }
          debugPrint('[THERMAL] Logo binarizada: preto=[1m$black[0m branco=[1m$white[0m');
          bytes += generator.imageRaster(grayscaleImage, align: PosAlign.center, highDensityHorizontal: true, highDensityVertical: true);
        }
      } catch (e) {
        debugPrint("Erro ao carregar/processar a imagem: $e");
        // Continue sem a imagem se houver erro
      }
      // Feed controlado para posicionar a próxima etiqueta
      //bytes += generator.feed(1);

      //bytes += generator.reset();
      // Enviar dados para impressora
      //bytes += generator.cut();

      debugPrint('[THERMAL] bytes enviados=${bytes.length} etiquetas=${etiqueta.idEtiquetas}');
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }
}
