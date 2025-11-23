import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/services/niimbot_print_bluetooth_thermal_service.dart';

enum PrinterConnectionState { disconnected, connecting, connected }

class NiimbotImpressorasController extends GetxController {
  NiimbotPrintBluetoothThermalService printService =
      NiimbotPrintBluetoothThermalService();

  // Estado de conexão da impressora para UI (desconectado, conectando, conectado)
  // Usado para transições visualmente claras (vermelho -> amarelo -> verde)
  final _printerConnectionState = PrinterConnectionState.disconnected.obs;
  Rx<PrinterConnectionState> get getPrinterConnectionState => _printerConnectionState;

  // Indica se o warmup pós-conexão já foi executado (evitar páginas em branco iniciais)
  bool _connectionWarmupDone = true;

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

  // Fila que armazena as imagens das etiquetas aguardando envio
  final Queue<ui.Image> _printQueue = Queue<ui.Image>();
  // Indica se a fila está em processamento neste momento
  bool _isProcessingQueue = false;
  final _processingQueue = false.obs;
  RxBool get getIsProcessingQueue => _processingQueue;

  // Exposição simples para UI: está capturando/enfileirando agora
  bool get isCapturandoOuProcessando => _processingQueue.value || _isProcessingQueue;

  // Reseta completamente a fila de impressão (utilizado por algumas telas)
  void resetFila() {
    _printQueue.clear();
    _isProcessingQueue = false;
    _processingQueue.value = false;
    _processingQueue.refresh();
    setQtdFila = 0;
  }

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


  Future<bool> isBluetoothEnabled() async {
    return await printService.isBluetoothEnabled();
  }

  Future<void> loadImpressoras() async {
    _listaImpressoras.value = await printService.loadDevices();
    _listaImpressoras.refresh();
    setStatusListaImpressoras = StatusListaImpressoras.success;
  }

  Future<bool> connectDevices({required BluetoothDevice device}) async {
    debugPrint("CONTROLLER CONNECTDEVICES: ${device.name}");
    try {
      // Indica para a UI que estamos tentando conectar
      _printerConnectionState.value = PrinterConnectionState.connecting;
      _printerConnectionState.refresh();
      // Tenta conectar e obtem estado real do plugin
      bool connected = await printService.connectDevices(
        device: device,
        sizeLabelPrint: _sizeLabelPrint.value,
      );

      if (connected) {
        _impressoraConectada.value = device;
        _impressoraConectada.refresh();
        _printerConnectionState.value = PrinterConnectionState.connected;
        _printerConnectionState.refresh();
        // marca warmup pendente após conexão bem sucedida
        _connectionWarmupDone = false;
        debugPrint("CONTROLLER: Impressora conectada com sucesso: ${device.name}");
      } else {
        // assegura que o controle local reflete desconexão
        _impressoraConectada.value = BluetoothDevice(name: '', address: '');
        _impressoraConectada.refresh();
        _printerConnectionState.value = PrinterConnectionState.disconnected;
        _printerConnectionState.refresh();
        debugPrint("CONTROLLER: Falha ao conectar impressora: ${device.name}");
      }
      return connected;
    } catch (e) {
      debugPrint("ERRO ao conectar dispositivo: $e");
      _impressoraConectada.value = BluetoothDevice(name: '', address: '');
      _impressoraConectada.refresh();
      _printerConnectionState.value = PrinterConnectionState.disconnected;
      _printerConnectionState.refresh();
      return false;
    }
  }

  Future<bool> disconnectDevice() async {
    _impressoraConectada.value = BluetoothDevice(name: '', address: '');
    _impressoraConectada.refresh();
    _printerConnectionState.value = PrinterConnectionState.disconnected;
    _printerConnectionState.refresh();
    // se desconectou, considera warmup como feito
    _connectionWarmupDone = true;
    return await printService.disconnectDevice();
  }

  Future<void> enviaEtiqueta({required GlobalKey key, int? numEtiqueta}) async {
    try {
      // Limpa qualquer fila/histórico remanescente antes de iniciar nova captura/impressão
      resetFila();
      if (_impressoraConectada.value.name != "") {
        // Verifica o estado real da conexão do plugin antes de capturar/enfileirar
        final bool pluginConnected = await printService.isConnected();
        if (!pluginConnected) {
          // Atualiza estado interno para refletir desconexão
          _impressoraConectada.value = BluetoothDevice(name: '', address: '');
          _impressoraConectada.refresh();
          throw CustomException(message: "Impressora não conectada");
        }

        // Marca na UI que iniciamos o processamento (captura + enfileiramento)
        _processingQueue.value = true;
        _processingQueue.refresh();
        // Feedback opcional removido (retorno ao comportamento simples)

        ui.Image image = await captureWidgetAsPng(key);

        // Salva uma prévia temporária em PNG para diagnóstico (permite inspecionar visualmente o que será impresso)
        try {
          final ByteData? pngData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (pngData != null) {
            final tmpDir = Directory.systemTemp.path;
            final fileName = 'etiqueta_${numEtiqueta ?? 'noid'}_${DateTime.now().millisecondsSinceEpoch}.png';
            final filePath = '$tmpDir/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(pngData.buffer.asUint8List());
            debugPrint('Prévia da etiqueta salva: $filePath (numEtiqueta=${numEtiqueta ?? 'null'})');
          }
        } catch (e) {
          debugPrint('Erro ao salvar preview PNG: $e');
        }

        await addEtiquetaFila(image);
        // Observação: não exibimos snackbar de "sucesso final" aqui — apenas após
        // confirmação do plugin de que os bytes foram aceitos pela impressora.
      } else {
        throw CustomException(message: "Você não está conectado a impressora!");
      }
    } catch (e) {
      // Garante que o indicador de processamento seja desligado em caso de erro
      _processingQueue.value = false;
      _processingQueue.refresh();
      throw CustomException(message: "ERRO ENVIAR ETIQUETA: ${e.toString()}");
    }
  }

  Future<void> addEtiquetaFila(ui.Image image) async {
    _printQueue.add(image);
    setQtdFila = _printQueue.length;
    debugPrint("ADD FILA: ${DateTime.now()}");
    debugPrint('[NIIMBOT][QUEUE] Fila após adicionar tamanho=${_printQueue.length} hashPrimeiro=${_printQueue.isNotEmpty ? _printQueue.first.hashCode : 'vazia'}');
    // Notifica que a etiqueta foi apenas enfileirada (ainda não enviada à impressora)
    _safeSnackbar('Impressão', 'Etiqueta enfileirada para impressão');
    // Se fila recém-criada, dispara processamento
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
      // PixelRatio informado manualmente para debug (pode ser ajustado via controller)
      debugPrint("PIXELRATIO IMAGEM: ${_pixelRatio.value.toString()}");

      /*final double pixelRatio =
          _sizeLabelPrint.value.toSizeLabelPrintValues['targetWidthPx'] /
          boundary.size.width; */

      // Ajuste DPI real do modelo B1 (~203 DPI) em vez de 300 para evitar captura superdimensionada
      const double niimbotDpi = 203.0;
      const double mmToInch = 25.4;

      // Calcula a largura desejada da imagem em pixels
      final double targetWidthPx =
          (_sizeLabelPrint.value.toSizeLabelPrintValues['labelWidth'] /
              mmToInch) *
          niimbotDpi;

      // Cálculo: escala direta pela largura alvo / largura atual em pixels do boundary
      final double pixelRatio = targetWidthPx / boundary.size.width;
      final DateTime inicio = DateTime.now();
      debugPrint('[NIIMBOT][CAPTURE] boundary.size=${boundary.size.width}x${boundary.size.height} targetWidthPx=$targetWidthPx dpi=$niimbotDpi pixelRatio=$pixelRatio');
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final DateTime fim = DateTime.now();
      debugPrint('[NIIMBOT][CAPTURE] tempoCapturaMs=${fim.difference(inicio).inMilliseconds} imagemCapturada=${image.width}x${image.height}');
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

  // Converte buffer bruto (Uint8List) em ui.Image
  Future<ui.Image> convertUint8ListToUiImage(Uint8List bytes) async {
    try {
      // Decodifica os bytes usando decodeImageFromList e retorna imagem para manipulação
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
    if (_printQueue.isEmpty) {
      _isProcessingQueue = false;
      _processingQueue.value = false;
      _processingQueue.refresh();
      return;
    }

    _isProcessingQueue = true;
    _processingQueue.value = true;
    _processingQueue.refresh();

    int jobCounter = 0;
    while (_printQueue.isNotEmpty) {
      final image = _printQueue.removeFirst();
      jobCounter++;
      final jobId = '${DateTime.now().millisecondsSinceEpoch}-$jobCounter';
      debugPrint('[NIIMBOT][QUEUE] Iniciando job=$jobId filaRestante=${_printQueue.length + 1}');
      // Feedback de progresso inicial
      _safeSnackbar('Impressão', 'Processando etiqueta...');
      // Se este é o primeiro envio após uma conexão recente, aguarda warmup maior
      if (!_connectionWarmupDone) {
        debugPrint('Aguardando warmup apos conexao (job $jobId) ...');
        // Delay mínimo apenas para estabilizar canal Bluetooth
        await Future.delayed(const Duration(milliseconds: 400));
        _connectionWarmupDone = true;
      }
      try {
        debugPrint('[NIIMBOT] Enviando job $jobId: ${DateTime.now()}');
        // Executa impressão multi-tentativa; warmup já tratado
        final res = await printService.printEtiqueta(
          imageEtiqueta: image,
          sizeLabelPrint: _sizeLabelPrint.value,
        );
        debugPrint("[NIIMBOT] Etiqueta enviada ($jobId): ${DateTime.now()} - res: $res");
        if (res) {
          // Se resultado OK mas baixa razão de preto pode ser suspeita de etiqueta em branco
          _safeSnackbar('Impressão', 'Etiqueta enviada para a impressora');
          // Se apenas uma etiqueta foi enviada e resultado true, libera fila visual
        } else {
          _safeSnackbar('Erro na impressão', 'Falha ao enviar para a impressora');
        }
        // Marca warmup como realizado após primeiro envio
        if (!_connectionWarmupDone) _connectionWarmupDone = true;
      } catch (e) {
        // Faz log do erro e notifica o usuário sem interromper a fila
        debugPrint("[NIIMBOT] Erro ao enviar etiqueta ($jobId): ${e.toString()}");
        _safeSnackbar('Erro ao imprimir', e.toString());
      }

      // Atualiza contador de itens restantes na fila
      setQtdFila = _printQueue.length;
      // Delay curto para evitar sobrecarga ou travamentos do plugin
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('[NIIMBOT][QUEUE] Finalizado job=$jobId filaRestante=${_printQueue.length}');
    }

    _isProcessingQueue = false;
    _processingQueue.value = false;
    _processingQueue.refresh();
    _printQueue.clear();
  }

  // Exibe snackbar de forma segura (evita exceção quando não há contexto disponível)
  void _safeSnackbar(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final ctx = Get.context;
        if (ctx != null) {
          // Utiliza ScaffoldMessenger se houver contexto (evita problemas do Get.snackbar)
          try {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(message)),
            );
            return;
          } catch (e) {
            debugPrint('Falha ao exibir SnackBar via ScaffoldMessenger: $e');
          }
        }
        // Sem contexto disponível: faz fallback para log (evitando NullCheck anterior do Get.snackbar)
        debugPrint('Snackbar fallback -> $title: $message');
      } catch (e) {
        debugPrint('Falha ao agendar/exibir snackbar: $e');
      }
    });
  }
}

enum StatusListaImpressoras { loading, success, error }
