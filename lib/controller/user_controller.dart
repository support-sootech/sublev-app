import 'package:get/get.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/repositories/login_repository.dart';

class UserController extends GetxController {
  final LoginRepository loginRepository = LoginRepository();

  final _state = UserState.initial.obs;
  Rx<UserState> get getState => _state.value.obs;
  set setState(UserState state) => _state.value = state;

  Future login({required String cpf, required String senha}) async {
    setState = UserState.loading;
    try {
      await loginRepository.login(cpf: cpf, senha: senha);
      setState = UserState.success;
    } catch (e) {
      setState = UserState.error;
      throw CustomException(message: e.toString());
    }
  }
}

enum UserState { initial, loading, success, error }
