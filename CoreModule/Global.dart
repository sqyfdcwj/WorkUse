
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

  checkPO("Check PO"),
  approvePO("Approve PO"),
  approvePOHist("Approve History"),
  salesOrder("Sales Order"),
  ;

  @override final String displayName;
  const Module(this.displayName);
}

final global = Global();

class Global {

  Global._() {
    curCompany.addListener(() {
      webApi.setRequestAdditionalInfo("company_id", curCompanyId);
    });
  }
  static final _instance = Global._();
  factory Global() => _instance;

  bool _isLogin = false;
  final Map<String, String> _curUser = {};
  String get username => _curUser["username"] ?? "";

  final ValueNotifier<Map<String, String>?> curCompany = ValueNotifier(null);
  final ValueNotifier<Module> curModule = ValueNotifier(Module.checkPO);

  String get curCompanyId => curCompany.value?["company_id"] ?? "0";

  void login(Map<String, String> user) {
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

  void logout() {
    if (!_isLogin) {
      return;
    }
    _curUser.keys.forEach(webApi.unsetRequestAdditionalInfo);
    _isLogin = false;
  }
}