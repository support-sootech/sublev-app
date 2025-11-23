import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/config/handle_dio_error.dart';
import 'package:ootech/models/user_model.dart';
import 'package:ootech/repositories/user_shared_preferences_repository.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class LoginRepository {
  final service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();
  late UserSharedPreferencesRepository userSharedPreferencesRepository =
      UserSharedPreferencesRepository();

  Future<UserModel> login({required String cpf, required String senha}) async {
    var isConnected = await networkAccess.checkNetworkAcess();
    if (!isConnected) {
      throw CustomException(message: "Você está sem conexão a internet!");
    }

    UserModel userModel;
    debugPrint('REPOSITORY LOGIN: ${cpf} - ${senha}');

    try {
      final endPoint = "/app-login";
      final response = await service.dio.post(
        endPoint,
        data: {'cpf': cpf, 'senha': senha},
      );
      debugPrint("REPOSITORY LOGIN 1: ${response.toString()}");
      if (response.data['success'] == true) {
        userModel = UserModel.fromJson(response.data['data']);
        await userSharedPreferencesRepository.setUserSharedPreferences(
          userModel,
        );
      } else {
        debugPrint("REPOSITORY LOGIN ERROR: ${response.toString()}");
        throw CustomException(message: response.data['msg']);
      }
    } on DioException catch (dioErr) {
      debugPrint("REPOSITORY ERROR 1: ${dioErr.toString()}");
      throw CustomException(message: handleDioError(dioErr));
    } catch (e) {
      debugPrint("REPOSITORY ERROR 2: ${e.toString()}");
      throw CustomException(message: e.toString());
    }
    return userModel;
  }
}
