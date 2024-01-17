
import 'package:flutter/material.dart';
import 'Export.dart';

final clMgr = ColorManager();

class ColorManager extends ManagerBootstrapMap<Color> {

  ColorManager._();
  static final _instance = ColorManager._();
  factory ColorManager() => _instance;

  @override get defaultValue => Colors.transparent;
  @override get sourceFieldName => "color_list";
  @override get uniqueField => "color_name";
  @override get webApiRequest => WebApi().postSingle(
    sqlGroupName: SqlGroupName.getColor,
    param: {}
  );

  @override
  Color getFromMap(Map<String, String> map) {
    return Color.fromARGB(
      int.tryParse(map["a"] ?? "0") ?? 0,
      int.tryParse(map["r"] ?? "0") ?? 0,
      int.tryParse(map["g"] ?? "0") ?? 0,
      int.tryParse(map["b"] ?? "0") ?? 0,
    );
  }
}