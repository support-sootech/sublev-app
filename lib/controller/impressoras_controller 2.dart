import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/etiqueta_model.dart';
import 'package:ootech/services/print_bluetooth_thermal_service.dart';

class ImpressorasController extends GetxController {
  PrintBluetoothThermalService printBluetoothThermalService =
      PrintBluetoothThermalService();

  final _statusListaImpressoras = StatusListaImpressoras.loading.obs;
  Rx<StatusListaImpressoras> get getStatusListaImpressoras =>
      _statusListaImpressoras.value.obs;
  set setStatusListaImpressoras(
    StatusListaImpressoras statusListaImpressoras,
  ) => _statusListaImpressoras.value = statusListaImpressoras;

  final _listaImpressoras = [].obs;
  RxList get getListaImpressoras => _listaImpressoras;

  final _impressoraConectada = ''.obs;
  RxString get getImpressoraConectada => _impressoraConectada;

  Future<void> loadImpressoras() async {
    _listaImpressoras.value = await printBluetoothThermalService.loadDevices();
    debugPrint("LISTA DE IMPRESSRAS: ${_listaImpressoras}");
    _listaImpressoras.refresh();
    setStatusListaImpressoras = StatusListaImpressoras.success;
  }

  Future<bool> isBbluetoothEnabled() async {
    return await printBluetoothThermalService.isBbluetoothEnabled();
  }

  Future<bool> connectDevices({required String mac}) async {
    var connected = await printBluetoothThermalService.connected;
    if (connected) {
      return false;
    }
    bool fg = await printBluetoothThermalService.connectDevices(mac: mac);
    if (fg) {
      _impressoraConectada.value = mac;
      _impressoraConectada.refresh();
    }
    return fg;
  }

  Future<bool> disconnectDevice() async {
    _impressoraConectada.value = '';
    _impressoraConectada.refresh();
    return await printBluetoothThermalService.disconnectDevice();
  }

  Future imprimirEtiqueta({required EtiquetaModel etiqueta}) async {
    bool isConnected = await printBluetoothThermalService.isConnected();
    if (isConnected) {
      printBluetoothThermalService.imprimirEtiqueta(etiqueta: etiqueta);
    } else {
      throw CustomException(message: "Você não está conectado a impressora!");
    }
  }
}

enum StatusListaImpressoras { loading, success, error }
