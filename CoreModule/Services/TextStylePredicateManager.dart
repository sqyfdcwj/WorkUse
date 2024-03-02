
import 'package:flutter/material.dart';
import '../Export.dart';

final tspMgr = TextStylePredicateManager();

class TextStylePredicateManager extends SingleTypeManagerBootstrap<TextStylePredicate>
  with SingleTypeManagerBootstrapMapMixin<TextStylePredicate> {

  TextStylePredicateManager._();
  static final _instance = TextStylePredicateManager._();
  factory TextStylePredicateManager() => _instance;

  @override
  final TextStylePredicate defaultValue = TextStylePredicate(
    uniqueName: "",
    method: "",
    predicateOrder: -1,
    compareValue: "",
    textStyle: TextStyleManager().defaultValue,
  );
  @override final String sourceFieldName = "text_style_predicate_list";
  @override final String uniqueField = "";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getTextStylePredicate);

  /// Key: combined_name (sql_group_name + '_' + sql_display_name)
  /// Val: sql_name
  final StringMap _sqlNameMap = {};

  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!super.initWithWebApiResult(webApiResult)) { return false; }
    // Initialized predicate data
    final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
    final uniqueNameSet = <String>{};
    final allPredicateList = list.map(getFromMap).toList();
    for (final element in allPredicateList) {
      uniqueNameSet.add(element.uniqueName);
    }
    for (final uniqueName in uniqueNameSet) {
      final predicateList = allPredicateList.where((p) => p.uniqueName == uniqueName).toList();
      if (predicateList.isEmpty) {
        continue;
      }
      // Sort with ascending predicateOrder
      predicateList.sort((lhs, rhs) => lhs.predicateOrder > rhs.predicateOrder ? 1 : -1);

      // Convert the list into linked list
      dataMap[uniqueName] = predicateList.first;
      TextStylePredicate curr = predicateList.first;
      for (int i = 0; i < predicateList.length; i++) {
        if (i != predicateList.length - 1) {
          curr._next = predicateList[i + 1];
          curr = curr._next!;
        }
      }
    }

    // combined_name = lower(sql_group_name) + '_' + lower(sql_display_name)
    // Every tuple of (sql_group_name, sql_display_name) is unique and has corresponding sql_name
    final combinedNameList = webApiResult.asListStringMap(fieldName: "combined_name_list");
    for (final map in combinedNameList) {
      _sqlNameMap[map["combined_name"] ?? ""] = map["sql_name"] ?? "";
    }

    return true;
  }

  @override
  TextStylePredicate getFromMap(StringMap map) {
    return TextStylePredicate(
      uniqueName: map["unique_name"] ?? "",
      predicateOrder: int.tryParse(map["predicate_order"] ?? "0") ?? 0,
      method: map["method"] ?? "",
      compareValue: map["compare_value"] ?? "",
      textStyle: tsMgr.getFromMap(map),
    );
  }

  String getSqlName(String sqlGroupName, String sqlDisplayName) {
    final combinedName = sqlGroupName.toLowerCase() + "_" + sqlDisplayName.toLowerCase();
    return _sqlNameMap[combinedName] ?? "";
  }

  String getUniqueName(String sqlGroupName, String sqlDisplayName, String fieldName) {
    return getSqlName(sqlGroupName, sqlDisplayName) + "_" + fieldName;
  }

  TextStyle? getTextStyle(String uniqueName, String value) {
    TextStylePredicate? curr = get(uniqueName);
    bool isEnd = false;
    while (curr != null && !isEnd) {
      if (curr.isMatch(value)) {
        isEnd = true;
      } else {
        curr = curr._next;
      }
    }
    return curr?.textStyle;
  }
}

/// Represented in linked-list
class TextStylePredicate {

  final String uniqueName;
  final int predicateOrder;
  final String method;
  final String compareValue;
  final TextStyle? textStyle;

  TextStylePredicate? _next;

  TextStylePredicate({
    required this.uniqueName,
    required this.predicateOrder,
    required this.method,
    required this.compareValue,
    required this.textStyle,
  });

  bool isMatch(String value) {
    switch (method) {
      case "eq":    return value == compareValue;
      case "regex": return RegExp(compareValue).hasMatch(value);
      default:      return true;
    }
  }
}
