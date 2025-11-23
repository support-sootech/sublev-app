import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/services/niimbot_print_bluetooth_thermal_service.dart';

class NiimbotImpressorasController extends GetxController {
  NiimbotPrintBluetoothThermalService printService =
      NiimbotPrintBluetoothThermalService();

  final _statusListaImpressoras = StatusListaImpressoras.loading.obs;
  Rx<StatusListaImpressoras> get getStatusListaImpressoras =>
      _statusListaImpressoras.value.obs;
  set setStatusListaImpressoras(
    StatusListaImpressoras statusListaImpressoras,
  ) => _statusListaImpressoras.value = statusListaImpressoras;

  final _listaImpressoras = <BluetoothDevice>[].obs;
  RxList<BluetoothDevice> get getListaImpressoras => _listaImpressoras;

  final _impressoraConectada = BluetoothDevice(name: '', address: '').obs;
  Rx<BluetoothDevice> get getImpressoraConectada => _impressoraConectada;

  final _sizeLabelPrint = SizeLabelPrint.$50_x_30.obs;
  Rx<SizeLabelPrint> get getSizeLabelPrint => _sizeLabelPrint;
  set setSizeLabelPrint(SizeLabelPrint sizeLabelPrint) {
    _sizeLabelPrint.value = sizeLabelPrint;
    _sizeLabelPrint.refresh();
    debugPrint("SET SIZE LABEL PRINT: ${sizeLabelPrint.toString()}");
  }

  // Fila para armazenar as etiquetas
  final Queue<ui.Image> _printQueue = Queue<ui.Image>();
  // Controla a fila está sendo processada
  bool _isProcessingQueue = false;

  //_printQueue.clear();

  final _qtdFila = 0.obs;
  Rx<int> get getQtdFila => _qtdFila;
  set setQtdFila(int qtdFila) {
    _qtdFila.value = qtdFila;
    _qtdFila.refresh();
  }

  final _pixelRatio = 5.5.obs;
  Rx<double> get getPixelRatio => _pixelRatio;
  set setPixelRatio(double pixelRatio) {
    _pixelRatio.value = pixelRatio;
    //_pixelRatio.refresh();
  }

  Future<bool> isBbluetoothEnabled() async {
    return await printService.isBbluetoothEnabled();
  }

  Future<void> loadImpressoras() async {
    _listaImpressoras.value = await printService.loadDevices();
    _listaImpressoras.refresh();
    setStatusListaImpressoras = StatusListaImpressoras.success;
  }

  Future<bool> connectDevices({required BluetoothDevice device}) async {
    debugPrint("CONTROLLER CONNECTDEVICES: ${device.name}");

    try {
      bool fg = await printService.connectDevices(
        device: device,
        sizeLabelPrint: _sizeLabelPrint.value,
      );
      if (fg) {
        _impressoraConectada.value = device;
        _impressoraConectada.refresh();

        //await Future.delayed(Duration(seconds: 1));
        //debugPrint("Impressora conectada e teste realizado");
      }
      return fg;
    } catch (e) {
      debugPrint("ERRO ao conectar dispositivo: $e");
      return false;
    }
  }

  Future<bool> disconnectDevice() async {
    _impressoraConectada.value = BluetoothDevice(name: '', address: '');
    _impressoraConectada.refresh();
    return await printService.disconnectDevice();
  }

  Future<void> enviaEtiqueta({required GlobalKey key}) async {
    try {
      if (_impressoraConectada.value.name != "") {
        ui.Image image = await captureWidgetAsPng(key);
        //ui.Image image = await convertUint8ListToUiImage(bytes);
        await addEtiquetaFila(image);
      } else {
        throw CustomException(message: "Você não está conectado a impressora!");
      }
    } catch (e) {
      throw CustomException(message: "ERRO ENVIAR ETIQUETA: ${e.toString()}");
    }
  }

  Future<void> addEtiquetaFila(ui.Image image) async {
    _printQueue.add(image);
    setQtdFila = _printQueue.length;
    debugPrint("ADD FILA: ${DateTime.now()}");
    if (!_isProcessingQueue) {
      await _imprimirEtiqueta();
    }
  }

  Future<ui.Image> captureWidgetAsPng(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw CustomException(
          message: "Erro: RenderRepaintBoundary não encontrado",
        );
      }
      // Ajuste o pixelRatio conforme necessário
      debugPrint("PIXELRATIO IMAGEM: ${_pixelRatio.value.toString()}");

      /*final double pixelRatio =
          _sizeLabelPrint.value.toSizeLabelPrintValues['targetWidthPx'] /
          boundary.size.width; */

      const double niimbotDpi = 300.0;
      const double mmToInch = 25.4;

      // Calcula a largura desejada da imagem em pixels
      final double targetWidthPx =
          (_sizeLabelPrint.value.toSizeLabelPrintValues['labelWidth'] /
              mmToInch) *
          niimbotDpi;

      final double pixelRatio = (targetWidthPx / boundary.size.width) + 1.8;
      debugPrint("PIXELRATIO IMAGEM: ${pixelRatio.toString()}");

      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      //await image.toByteData(format: ui.ImageByteFormat.png);
      return image;
      /*
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      */
      //debugPrint("CAPTURA IMAGEM: ${DateTime.now()}");
      //return byteData!.buffer.asUint8List();
    } catch (e) {
      throw CustomException(message: "Erro: ${e.toString()}");
    }
  }

  // FUNÇÃO: Converte Uint8List para ui.Image
  Future<ui.Image> convertUint8ListToUiImage(Uint8List bytes) async {
    try {
      // Usa ui.decodeImageFromList para decodificar os bytes em um ui.Image
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      debugPrint("CONVERTE IMAGEM: ${DateTime.now()}");
      return await completer.future;
    } catch (e) {
      throw CustomException(message: "ERRO CONVERTER: ${e.toString()}");
    }
  }

  Future _imprimirEtiqueta() async {
    try {
      if (_printQueue.isEmpty) {
        _isProcessingQueue = false;
        return;
      }
      _isProcessingQueue = true;

      while (_printQueue.isNotEmpty) {
        final image = _printQueue.removeFirst();
        await printService.printEtiqueta(
          imageEtiqueta: image,
          sizeLabelPrint: _sizeLabelPrint.value,
        );
        setQtdFila = _printQueue.length;
      }
      _isProcessingQueue = false;
      _printQueue.clear();
    } catch (e) {
      debugPrint("ERRO IMPRIMIR ETIQUETA: ${e.toString()}");
    }
  }
}

enum StatusListaImpressoras { loading, success, error }
