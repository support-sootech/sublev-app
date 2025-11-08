import 'dart:convert';
import 'package:ootech/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPreferencesRepository {
  static String get _APP_PREFS_USER => "app_prefs_user";

  late UserModel userLogado;

  Future<bool> setUserSharedPreferences(UserModel userModel) async {
    final preferences = await SharedPreferences.getInstance();
    return await preferences.setString(_APP_PREFS_USER, json.encode(userModel));
  }

  static Future<bool> isLogged() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_APP_PREFS_USER) != null ? true : false;
  }

  Future<UserModel> getUserSharedPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    if (preferences.getString(_APP_PREFS_USER) != null) {
      userLogado = UserModel.fromJson(
        jsonDecode(preferences.getString(_APP_PREFS_USER)!),
      );
    }
    return userLogado;
  }

  Future removeUserSharedPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_APP_PREFS_USER);
  }
}
