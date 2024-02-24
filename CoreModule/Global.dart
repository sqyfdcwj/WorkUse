
import 'package:flutter/material.dart';
import 'EnumMixin.dart';

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

  Global._();
  static final _instance = Global._();
  factory Global() => _instance;

  String get userId => _curUser["user_id"] ?? "";
  String get username => _curUser["username"] ?? "";
  String get userLv => _curUser["user_lv"] ?? "";
  String get staffId => _curUser["staff_id"] ?? "";

  final Map<String, String> _curUser = {};
  set curUser(Map<String, String> map) {
    for (final entry in map.entries) {
      _curUser[entry.key] = entry.value;
    }
  }
  //
  // void setUserImage({ required Map<String, String> map }) {
  //   for (final entry in map.entries) {
  //     _curUser[entry.key] = entry.value;
  //   }
  // }

  final ValueNotifier<Map<String, String>?> curCompany = ValueNotifier(null);
  final ValueNotifier<Module> curModule = ValueNotifier(Module.checkPO);

  String get curCompanyId => curCompany.value?["company_id"] ?? "0";
}