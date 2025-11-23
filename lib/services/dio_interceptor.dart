import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';

class DioInterceptor extends Interceptor {
  var user = UserModel();
  Future<void>? _loadingUser;

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
    debugPrint("INTERCEPTOR HEADERS ${options.headers}");
    debugPrint("INTERCEPTOR PATH ${options.path}");
    debugPrint("INTERCEPTOR URI ${options.uri}");
    debugPrint("INTERCEPTOR URI ${options.data}");
    debugPrint("INTERCEPTOR DATE ${DateTime.now()}");
    debugPrint("---------------------------------------------------------");
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint("=== DIO INTERCEPTOR ERROR ===");
    debugPrint("Error Type: ${err.type}");
    debugPrint("Error Message: ${err.message}");
    debugPrint("Response: ${err.response?.data}");
    debugPrint("Status Code: ${err.response?.statusCode}");
    debugPrint("Request Path: ${err.requestOptions.path}");
    debugPrint("=============================");
    // Você pode adicionar lógica personalizada aqui
    // Por exemplo, logout automático em caso de token inválido
    if (err.response?.statusCode == 401) {
      debugPrint("Token inválido - considerando logout automático");
      // Aqui você poderia implementar logout automático
    }
    debugPrint("DioInterceptor Err: ${err.response}");
    debugPrint("DioInterceptor handler: ${handler.toString()}");

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint("=== DIO INTERCEPTOR RESPONSE ===");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Data: ${response.data}");
    debugPrint("================================");

    super.onResponse(response, handler);
  }
}
