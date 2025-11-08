import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';

class DioInterceptor extends Interceptor {
  var user = UserModel();

  DioInterceptor() {
    _initializeUser();
  }

  _initializeUser() async {
    try {
      user = await UserSharedPreferencesRepository().getUserSharedPreferences();
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
      user = UserModel(); // Fallback para usuário vazio
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (user.hash != null) {
      options.headers["Token-User"] = user.hash;
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
