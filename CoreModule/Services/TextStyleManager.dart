
import 'package:flutter/material.dart';
import '../Export.dart';

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
  TextStyle getFromMap(StringMap map) {
    return TextStyle(
      fontSize: double.tryParse(map["font_size"] ?? "14") ?? 14,
      color: DynamicWidgetData.parseColor(map, fieldA: "a", fieldR: "r", fieldG: "g", fieldB: "b"),
      fontWeight: parseFontWeight(map),
      fontStyle: (int.tryParse(map["is_italic"] ?? "0") ?? 0) == 1
        ? FontStyle.italic
        : FontStyle.normal,
    );
  }

  Color? getColor(String name) => get(name)?.color;

  FontWeight parseFontWeight(StringMap map) {
    int index = int.tryParse(map["font_weight"] ?? "4") ?? 4;
    if (index >= 1 && index <= 9) {
      // [w100, w200, w300, w400, w500, w600, w700, w800, w900]
      return FontWeight.values[index - 1];
    } else {
      return FontWeight.normal; // This is equal to w400
    }
  }
}
