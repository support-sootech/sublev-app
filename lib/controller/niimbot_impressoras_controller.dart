import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/functions_global.dart';
import 'package:ootech/services/niimbot_print_bluetooth_thermal_service.dart';

// Enum padronizado de estado de conexão da impressora usado pelas telas
enum PrinterConnectionState { disconnected, connecting, connected }

// Tipos padronizados de snackbar (mover para topo para uso global)
enum SnackBarType { queue, success, error, info }

class NiimbotImpressorasController extends GetxController {
  NiimbotPrintBluetoothThermalService printService =
      NiimbotPrintBluetoothThermalService();

  // Instrumentação para diagnosticar duplicação de snackbars.
  int _snackbarSeq = 0; // contador incremental
  DateTime? _lastSnackbarAt;
  String? _lastSnackbarSignature; // combina type+message
  static const Duration _dedupeWindow = Duration(seconds: 3);

  // Removido warmup global; teste é executado em cada conexão conforme solicitação.

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

  // Estado da conexão (compatível com telas que exibem ícones de status)
  final _printerConnectionState = PrinterConnectionState.disconnected.obs;
  Rx<PrinterConnectionState> get getPrinterConnectionState => _printerConnectionState;

  // Fila e flags de processamento
  final Queue<ui.Image> _printQueue = Queue<ui.Image>();
  bool _isProcessingQueue = false; // se está enviando atualmente
  final _processingQueue = false.obs; // exposto para overlays
  RxBool get getIsProcessingQueue => _processingQueue;
  bool _connectionWarmupDone = false; // ficará true somente após teste de conexão

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

  // Verifica se o bluetooth do aparelho está habilitado
  Future<bool> isBluetoothEnabled() async {
    return await printService.isBbluetoothEnabled();
  }

  // Alias para compatibilidade com telas antigas que usam o nome errado
  Future<bool> isBbluetoothEnabled() async {
    return isBluetoothEnabled();
  }

  Future<void> loadImpressoras() async {
    _listaImpressoras.value = await printService.loadDevices();
    _listaImpressoras.refresh();
    setStatusListaImpressoras = StatusListaImpressoras.success;
  }

  Future<bool> connectDevices({required BluetoothDevice device}) async {
    debugPrint("CONTROLLER CONNECTDEVICES: ${device.name}");
    try {
      _printerConnectionState.value = PrinterConnectionState.connecting;
      _connectionWarmupDone = false;
      final bool connected = await printService.connectDevicesQuick(device: device);
      if (!connected) {
        _printerConnectionState.value = PrinterConnectionState.disconnected;
        return false;
      }
      _impressoraConectada.value = device;
      _impressoraConectada.refresh();
      _printerConnectionState.value = PrinterConnectionState.connected;
      debugPrint('Conexão estabelecida: ${device.name}');
      // Sempre dispara teste de logo em cada conexão.
      unawaited(_runTesteLogoSempre(device));
      return true;
    } catch (e) {
      debugPrint('ERRO ao conectar dispositivo: $e');
      _printerConnectionState.value = PrinterConnectionState.disconnected;
      return false;
    }
  }

  // Método legado removido (warmup antigo); declaração eliminada para reduzir avisos não utilizados.

  Future<void> _runTesteLogoSempre(BluetoothDevice device) async {
    try {
      debugPrint('[TESTE LOGO] Iniciando para ${device.name}');
      // Usa densidade alta (default 4) para teste logo garantir preto forte.
      final bool ok = await printService.printTesteLogo(overrideDensity: 4);
      _connectionWarmupDone = true;
      debugPrint('[TESTE LOGO] Resultado=${ok ? 'sucesso' : 'falha'} para ${device.name}');
      if (_printQueue.isNotEmpty && !_isProcessingQueue) {
        debugPrint('[TESTE LOGO] Fila pendente (${_printQueue.length}), iniciando envio');
        unawaited(_imprimirEtiqueta());
      }
    } catch (e) {
      debugPrint('[TESTE LOGO] Falha: $e');
      _connectionWarmupDone = true;
      if (_printQueue.isNotEmpty && !_isProcessingQueue) unawaited(_imprimirEtiqueta());
    }
  }

  Future<bool> disconnectDevice() async {
    _impressoraConectada.value = BluetoothDevice(name: '', address: '');
    _impressoraConectada.refresh();
    _printerConnectionState.value = PrinterConnectionState.disconnected;
    return await printService.disconnectDevice();
  }

  // Enfileira uma etiqueta a partir da captura de um widget identificado pela key
  Future<void> enviaEtiqueta({required GlobalKey key, int? numEtiqueta}) async {
    try {
      // bloqueia se já há processamento em curso para evitar concorrência de sockets
      if (_isProcessingQueue) {
        _showAppSnackbar('Já existe uma etiqueta sendo processada. Aguarde.', SnackBarType.info);
        return;
      }
      if (_impressoraConectada.value.name.isEmpty) {
        _showAppSnackbar('Impressora não conectada', SnackBarType.error);
        throw CustomException(message: 'Impressora não conectada');
      }
      // captura imagem
      final ui.Image image = await captureWidgetAsPng(key);
      await addEtiquetaFila(image, numEtiqueta: numEtiqueta);
    } catch (e) {
      throw CustomException(message: 'ERRO ENVIAR ETIQUETA: ${e.toString()}');
    }
  }

  Future<void> addEtiquetaFila(ui.Image image, {int? numEtiqueta}) async {
    _printQueue.add(image);
    setQtdFila = _printQueue.length;
    debugPrint('ADD FILA: ${DateTime.now()} / fila=${_printQueue.length}');
    _showAppSnackbar('Etiqueta enfileirada para impressão', SnackBarType.queue);
    // Só inicia processamento se conexão concluída e warmup finalizado.
    if (!_isProcessingQueue && _printerConnectionState.value == PrinterConnectionState.connected && _connectionWarmupDone) {
      await _imprimirEtiqueta();
    } else {
      if (_printerConnectionState.value != PrinterConnectionState.connected) {
        _showAppSnackbar('Aguardando conexão da impressora...', SnackBarType.info);
      } else if (!_connectionWarmupDone) {
        _showAppSnackbar('Finalizando teste de conexão...', SnackBarType.info);
      }
    }
  }

  // Reinicializa a fila de impressão
  void resetFila() {
    _printQueue.clear();
    setQtdFila = 0;
    _isProcessingQueue = false;
    _processingQueue.value = false;
  }

  // Tipos padronizados de snackbar
  void _showAppSnackbar(String message, SnackBarType type) {
    final int seq = ++_snackbarSeq;
    final String signature = '${type.name}|$message';
    final DateTime now = DateTime.now();
    // Deduplicação temporal simples
    if (_lastSnackbarSignature == signature && _lastSnackbarAt != null && now.difference(_lastSnackbarAt!) < _dedupeWindow) {
      debugPrint('[SNACKBAR][skip][seq=$seq] duplicado dentro da janela ${_dedupeWindow.inSeconds}s type=${type.name} msg="$message"');
      return;
    }
    _lastSnackbarSignature = signature;
    _lastSnackbarAt = now;
    // Origem (frame principal após esta função na stack)
    String origin = '';
    try {
      final st = StackTrace.current.toString().split('\n');
      // Pula a primeira linha (esta função) e pega a próxima relevante
      origin = st.length > 1 ? st[1].trim() : st.first.trim();
    } catch (_) {}
    debugPrint('[SNACKBAR][emit][seq=$seq] type=${type.name} msg="$message" origin=$origin');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      if (ctx == null) return;
      Color bg;
      IconData icon;
      switch (type) {
        case SnackBarType.queue:
          bg = Colors.blueAccent; icon = Icons.playlist_add; break;
        case SnackBarType.success:
          bg = Colors.green.shade600; icon = Icons.check_circle_outline; break;
        case SnackBarType.error:
          bg = Colors.red.shade700; icon = Icons.error_outline; break;
        case SnackBarType.info:
          bg = Colors.green.shade600; icon = Icons.info_outline; break;
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
      // Evita empilhamento visual: remove snackbar atual antes de inserir outra.
      // (Chamada após agendar exibição garante que a anterior seja dispensada rapidamente.)
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    });
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
      // Versão anterior (qualidade forte): usa DPI real aproximado da B1 (~203) e não limita pixelRatio.
      debugPrint("PIXELRATIO IMAGEM (manual): ${_pixelRatio.value.toString()}");
      const double niimbotDpi = 203.0; // DPI real do modelo
      const double mmToInch = 25.4;
      final Map<String, dynamic> values = _sizeLabelPrint.value.toSizeLabelPrintValues;
      final double targetWidthPx = (values['labelWidth'] / mmToInch) * niimbotDpi;
      final double pixelRatio = targetWidthPx / boundary.size.width;
      final DateTime inicio = DateTime.now();
      debugPrint('[NIIMBOT][CAPTURE] boundary.size=${boundary.size.width}x${boundary.size.height} targetWidthPx=$targetWidthPx dpi=$niimbotDpi pixelRatio=$pixelRatio');
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
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
      bool overlayShown = false;
      void showOverlay() {
        if (overlayShown) return;
        overlayShown = true;
        final ctx = Get.context;
        if (ctx != null) {
          Get.dialog(
            WillPopScope(
              onWillPop: () async => false,
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 42, height: 42, child: CircularProgressIndicator()),
                        SizedBox(height: 16),
                        Text('Imprimindo etiqueta...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            barrierDismissible: false,
          );
        }
      }
      void hideOverlay() {
        if (!overlayShown) return;
        if (Get.isDialogOpen == true) Get.back();
        overlayShown = false;
      }

      showOverlay();
      _showAppSnackbar('Processando etiqueta...', SnackBarType.info);
      while (_printQueue.isNotEmpty) {
        final image = _printQueue.removeFirst();
        _processingQueue.value = true;
        if (!_connectionWarmupDone) {
          // Garantia extra caso warmup demore um pouco mais
          await Future.delayed(const Duration(milliseconds: 400));
          _connectionWarmupDone = true;
        }
        final res = await printService.printEtiqueta(
          imageEtiqueta: image,
          sizeLabelPrint: _sizeLabelPrint.value,
          forceResize: false,
          overrideDensity: 9, // mantém ajuste lógico para reforçar contraste
          highContrast: true,
          contrastThreshold: 150,
          repeatPasses: 1,
          overstrike: true,
          dilate: true,
          interPassDelayMs: 140,
          thresholdOffset: 10,
          gammaCorrection: 0.75,
          simulateMultiPassForDensity: false, // evita impressão física duplicada
        );
        setQtdFila = _printQueue.length;
        if (res == true) {
          _showAppSnackbar('Etiqueta enviada para a impressora', SnackBarType.success);
        } else {
          _showAppSnackbar('Falha ao enviar para a impressora', SnackBarType.error);
        }
        // pequeno intervalo evita pressão no canal bluetooth
        await Future.delayed(const Duration(milliseconds: 180));
      }
      _isProcessingQueue = false;
      _processingQueue.value = false;
      _printQueue.clear();
      hideOverlay();
    } catch (e) {
      debugPrint("ERRO IMPRIMIR ETIQUETA: ${e.toString()}");
      _processingQueue.value = false;
      _showAppSnackbar(e.toString(), SnackBarType.error);
      if (Get.isDialogOpen == true) Get.back();
    }
  }
}

enum StatusListaImpressoras { loading, success, error }
