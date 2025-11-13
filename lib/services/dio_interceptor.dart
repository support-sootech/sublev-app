import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';

class DioInterceptor extends Interceptor {
  final UserSharedPreferencesRepository _userSharedPreferencesRepository =
      UserSharedPreferencesRepository();
  UserModel? _user;

  Future<UserModel?> _ensureUserLoaded() async {
    if (_user != null) {
      return _user;
    }

    try {
      _user = await _userSharedPreferencesRepository.getUserSharedPreferences();
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
      _user = UserModel();
    }

    return _user;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = await _ensureUserLoaded();
    final token = user?.hash;

    if (token != null && token.isNotEmpty) {
      options.headers["Token-User"] = token;
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
