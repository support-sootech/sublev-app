import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkAccess {
  Future<bool> checkNetworkAcess() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      return Future<bool>.value(true);
    } else {
      return Future<bool>.value(false);
    }
  }
}
