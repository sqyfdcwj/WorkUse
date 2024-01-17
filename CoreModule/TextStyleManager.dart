
import 'package:flutter/material.dart';
import 'Export.dart';

final tsMgr = TextStyleManager();

class TextStyleManager extends ManagerBootstrapMap<TextStyle> {

  TextStyleManager._();
  static final _instance = TextStyleManager._();
  factory TextStyleManager() => _instance;

  @override
  TextStyle get defaultValue => const TextStyle(
    fontSize: 14,
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  @override final String sourceFieldName = "text_style_list";
  @override final String uniqueField = "style_name";
  @override get webApiRequest => webApi.postSingle(
    sqlGroupName: SqlGroupName.getTextStyle,
    param: {}
  );

  @override
  TextStyle getFromMap(Map<String, String> map) {
    return TextStyle(
      fontSize: double.tryParse(map["font_size"] ?? "14") ?? 14,
      color: Color.fromARGB(
        int.tryParse(map["a"] ?? "255") ?? 255,
        int.tryParse(map["r"] ?? "0") ?? 0,
        int.tryParse(map["g"] ?? "0") ?? 0,
        int.tryParse(map["b"] ?? "0") ?? 0,
      ),
      fontWeight: (int.tryParse(map["is_bold"] ?? "0") ?? 0) == 1
        ? FontWeight.bold
        : FontWeight.normal,
      fontStyle: (int.tryParse(map["is_italic"] ?? "0") ?? 0) == 1
        ? FontStyle.italic
        : FontStyle.normal,
    );
  }
}