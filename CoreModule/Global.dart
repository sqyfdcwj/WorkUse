
import 'package:flutter/material.dart';
import 'EnumMixin.dart';

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

  String get userId => _userImage["user_id"] ?? "";
  String get username => _userImage["username"] ?? "";
  String get userLv => _userImage["user_lv"] ?? "";
  String get staffId => _userImage["staff_id"] ?? "";

  final Map<String, String> _userImage = {};
  void setUserImage({ required Map<String, String> map }) {
    for (final entry in map.entries) {
      _userImage[entry.key] = entry.value;
    }
  }

  /// When not logged in or there is any dialogs, disable user to open drawer by swping.
  final ValueNotifier<bool> allowOpenDrawer = ValueNotifier(false);

  final ValueNotifier<Map<String, String>?> curCompany = ValueNotifier(null);
  final ValueNotifier<Module> curModule = ValueNotifier(Module.checkPO);

  String get curCompanyId => curCompany.value?["company_id"] ?? "0";

  void enableOpenDrawer() => allowOpenDrawer.value = true;
  void disableOpenDrawer() => allowOpenDrawer.value = false;
}