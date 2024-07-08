
import 'package:flutter/material.dart';
import 'Export.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
BuildContext get rootNavigatorContext => rootNavigatorKey.currentContext!;
NavigatorState get rootNavigatorState => rootNavigatorKey.currentState!;

final TargetPlatform currentPlatform = Theme.of(rootNavigatorContext).platform;
late final bool isAndroid = currentPlatform == TargetPlatform.android;
late final bool isIOS = currentPlatform == TargetPlatform.iOS;

final rootScaffoldKey = GlobalKey<ScaffoldState>();
BuildContext get rootScaffoldContext => rootScaffoldKey.currentContext!;
ScaffoldState get rootScaffoldState => rootScaffoldKey.currentState!;

enum Module with EnumUniqueNameMixin {

  checkPO("Check Outstanding PO"),
  approvePO("Approve Checked PO"),
  approvePOHist("Approval PO History"),
  ;

  @override final String displayName;
  const Module(this.displayName);
}

final global = Global();

class Global {

  Global._() {
    curCompany.addListener(() {
      print("Global::curCompany listener, curCompanyId = $curCompanyId");

      // The user info may contains a company_id and we have to distinguish them
      webApi.setRequestAdditionalInfo("selected_company_id", curCompanyId);
    });
  }
  static final _instance = Global._();
  factory Global() => _instance;

  bool _isLogin = false;
  final StringMap _curUser = {};
  String get username => _curUser["username"] ?? "";

  bool get isSuperUser => (_curUser["is_super_user"] ?? "") == "1";

  final ValueNotifier<StringMap?> curCompany = ValueNotifier(null);
  final ValueNotifier<Module> curModule = ValueNotifier(Module.checkPO);

  String get curCompanyId => curCompany.value?["company_id"] ?? "0";

  /// Set state _login to true and update WebApi basic info
  void login(StringMap user) {
    if (_isLogin) {
      return;
    }
    _curUser.keys.forEach(webApi.unsetRequestAdditionalInfo);
    _curUser.addAll(user);
    for (var kv in _curUser.entries) {
      webApi.setRequestAdditionalInfo(kv.key, kv.value);
    }
    _isLogin = true;
  }

  /// Set state _login to false and clear WebApi basic info
  void logout() {
    if (!_isLogin) {
      return;
    }
    _curUser.keys.forEach(webApi.unsetRequestAdditionalInfo);
    _curUser.clear();
    _isLogin = false;
  }
}