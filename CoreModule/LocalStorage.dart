
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Export.dart';

class UserCredential {

  String login;
  String password;
  final ValueNotifier<bool> vnAutoLogin;

  bool get autoLogin => vnAutoLogin.value;
  set autoLogin(bool newValue) => vnAutoLogin.value = newValue;

  UserCredential(this.login, this.password, bool autoLogin)
    : vnAutoLogin = ValueNotifier(autoLogin);

  Future<void> save() => LocalStorage()._saveUserCredential(this);

  void onAutoLoginChanged(bool newValue) {
    autoLogin = newValue;
    LocalStorage()._saveUserCredential(this);
  }

  static Future<UserCredential> fromLocalStorage() {
    return LocalStorage()._readUserCredential();
  }
}

class LocalStorage extends BootstrapImpl {

  LocalStorage._();
  factory LocalStorage() => _instance;
  static final _instance = LocalStorage._();

  late final PackageInfo _packageInfo;
  late final SharedPreferences _pf;

  String get version => _packageInfo.version;
  String get prefix => _packageInfo.packageName;

  @override
  Future<bool> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _pf = await SharedPreferences.getInstance();
    return true;
  }

  Future<UserCredential> _readUserCredential() async {
    final login = _pf.getString(prefix + "login");
    final password = _pf.getString(prefix + "password");
    final autoLogin = _pf.getString(prefix + "auto_login");
    if (login != null && password != null && autoLogin != null) {
      return UserCredential(login, password, autoLogin == "1");
    } else {
      return UserCredential("", "", false);
    }
  }

  Future<void> _saveUserCredential(UserCredential credential) async {
    _pf.setString(prefix + "login", credential.login);
    _pf.setString(prefix + "password", credential.password);
    _pf.setString(prefix + "auto_login", credential.vnAutoLogin.value ? "1" : "0");
  }
}