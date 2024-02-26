
library text_style_manager;

import 'package:flutter/material.dart';
import 'Export.dart';

part 'TextStyleManager_var.dart';

final tsMgr = TextStyleManager();

/// Provides TextStyle and Color configuraion
class TextStyleManager extends SingleTypeManagerBootstrap<TextStyle>
  with SingleTypeManagerBootstrapMapMixin<TextStyle> {

  TextStyleManager._();
  static final _instance = TextStyleManager._();
  factory TextStyleManager() => _instance;

  @override
  TextStyle defaultValue = const TextStyle(
    fontSize: 14,
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );
  @override final String sourceFieldName = "text_style_list";
  @override final String uniqueField = "style_name";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getTextStyle);

  @override
  TextStyle getFromMap(Map<String, String> map) {
    return TextStyle(
      fontSize: double.tryParse(map["font_size"] ?? "14") ?? 14,
      color: DynamicWidgetData.parseColor(map, fieldA: "a", fieldR: "r", fieldG: "g", fieldB: "b"),
      fontWeight: (int.tryParse(map["is_bold"] ?? "0") ?? 0) == 1
        ? FontWeight.bold
        : FontWeight.normal,
      fontStyle: (int.tryParse(map["is_italic"] ?? "0") ?? 0) == 1
        ? FontStyle.italic
        : FontStyle.normal,
    );
  }

  Color? getColor(String name) => get(name)?.color;
}
