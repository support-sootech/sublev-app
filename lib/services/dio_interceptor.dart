import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/debug_log_service.dart';

class DioInterceptor extends Interceptor {
  var user = UserModel();
  Future<void>? _loadingUser;
  final DebugLogService _log = DebugLogService();

  DioInterceptor() {
    _loadingUser = _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      user = await UserSharedPreferencesRepository().getUserSharedPreferences();
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
      user = UserModel(); // Fallback para usuário vazio
    }
  }

  Future<void> _ensureUserLoaded() async {
    if (_loadingUser != null) {
      await _loadingUser;
      _loadingUser = null;
    }
    if (user.hash == null && user.idEmpresas == null) {
      _loadingUser = _initializeUser();
      await _loadingUser;
      _loadingUser = null;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _ensureUserLoaded();
    if (user.hash != null && user.hash!.isNotEmpty) {
      options.headers["Token-User"] = user.hash;
    }
    final empresaId = user.idEmpresas?.toString();
    if (empresaId != null && empresaId.isNotEmpty && empresaId != "0") {
      options.headers["X-Company-Id"] = empresaId;
    }
    
    _log.addLog("REQ: ${options.method} ${options.uri}");
    if (options.data != null) _log.addLog("DATA: ${options.data}");
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.addLog("ERROR: ${err.type} - ${err.message}");
    if (err.response != null) {
      _log.addLog("RESP_ERR [${err.response?.statusCode}]: ${err.response?.data}");
    }
    if (err.error != null) {
      _log.addLog("RAWERR: ${err.error.toString()}");
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.addLog("RESP [${response.statusCode}]: ${response.requestOptions.path}");
    super.onResponse(response, handler);
  }
}
