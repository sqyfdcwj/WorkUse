
import 'package:flutter/material.dart';
import '../Export.dart';

final dwMgr = DynamicWidgetManager();

class DynamicWidgetManager extends SingleTypeManagerBootstrap<DynamicWidgetData>
  with SingleTypeManagerBootstrapMapMixin<DynamicWidgetData> {

  DynamicWidgetManager._();
  static final _instance = DynamicWidgetManager._();
  factory DynamicWidgetManager() => _instance;

  @override final DynamicWidgetData defaultValue = DynamicWidgetData(
    configName: "Stub",
    id: -1,
    parentId: -1,
    widgetType: "",
    depth: -1,
    flex: 0,
    widgetOrder: 0,
    uniqueName: "",
    padding: EdgeInsets.zero,
    color: Colors.transparent,
    alignment: Alignment.topLeft,
  );

  @override final String sourceFieldName = "dynamic_widget_list";
  @override final String uniqueField = "config_name";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getDynamicWidget);

  @override
  String? initWithWebApiResult(WebApiResult webApiResult) {
    final result = super.initWithWebApiResult(webApiResult);
    if (result == null) {
      final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
      final widgetDataList = list.map(getFromMap).toList();
      final configNameSet = <String>{};
      final rootWidgetDataList = widgetDataList.where((data) => data.isRoot).toList();

      // Distinct on configName
      rootWidgetDataList.retainWhere((element) => configNameSet.add(element.configName));
      for (final rootData in rootWidgetDataList) {
        dataMap[rootData.configName] = rootData;
        _buildDynamicWidgetDataTree(rootData, widgetDataList);
      }

      final singleWidgetDataList = widgetDataList.where((data) => data.isSingle).toList();
      for (final singleData in singleWidgetDataList) {
        dataMap[singleData.configName] = singleData;
      }
    }
    return result;
  }

  void _buildDynamicWidgetDataTree(DynamicWidgetData data, List<DynamicWidgetData> widgetDataList) {
    final children = widgetDataList.where((widgetData) {
      return widgetData.configName == data.configName
          && widgetData.parentId == data.id
          && widgetData.depth == data.depth + 1;
    }).toList();

    final childrenHashCodeSet = <int>{};
    data._children.addAll(children);
    data._children.retainWhere((childrenData) => childrenHashCodeSet.add(childrenData.hashCode));

    // Sort with ascending widgetOrder
    data._children.sort((lhs, rhs) => lhs.widgetOrder > rhs.widgetOrder ? 1 : -1);
    for (final child in data._children) {
      _buildDynamicWidgetDataTree(child, widgetDataList);
    }
  }

  @override
  DynamicWidgetData getFromMap(StringMap map) {
    return DynamicWidgetData(
      id: int.tryParse(map["config_id"] ?? "0") ?? 0,
      parentId: int.tryParse(map["parent_config_id"] ?? "0") ?? 0,
      configName: map["config_name"] ?? "",
      widgetType: map["widget_type"] ?? "",
      depth: int.tryParse(map["depth"] ?? "0") ?? 0,
      flex: int.tryParse(map["flex"] ?? "0") ?? 0,
      widgetOrder: int.tryParse(map["widget_order"] ?? "0") ?? 0,
      uniqueName: map["unique_name"] ?? "",
      alignment: Alignment(
        double.tryParse(map["alignment_x"] ?? "-1.0") ?? -1.0,
        double.tryParse(map["alignment_y"] ?? "-1.0") ?? -1.0,
      ),
      padding: EdgeInsets.only(
        left: double.tryParse(map["padding_left"] ?? "0") ?? 0,
        right: double.tryParse(map["padding_right"] ?? "0") ?? 0,
        top: double.tryParse(map["padding_top"] ?? "0") ?? 0,
        bottom: double.tryParse(map["padding_bottom"] ?? "0") ?? 0,
      ),
      width: double.tryParse(map["width"] ?? ""),
      height: double.tryParse(map["height"] ?? ""),
      color: DynamicWidgetData.parseColor(map),
      textStyle: (int.tryParse(map["text_style_id"] ?? "0") ?? 0) == 0
        ? null
        : TextStyleManager().getFromMap(map),
      posLeft: double.tryParse(map["pos_left"] ?? ""),
      posRight: double.tryParse(map["pos_right"] ?? ""),
      posTop: double.tryParse(map["pos_top"] ?? ""),
      posBottom: double.tryParse(map["pos_bottom"] ?? ""),
      mainAxisAlignment: (String name) {
        return DynamicWidgetData._mainAxisAlignmentMap[name.toLowerCase()]
            ?? MainAxisAlignment.start;
      } (map["main_axis_alignment"] ?? ""),
      crossAxisAlignment: (String name) {
        return DynamicWidgetData._crossAxisAlignmentMap[name.toLowerCase()]
            ?? CrossAxisAlignment.start;
      } (map["cross_axis_alignment"] ?? ""),
      textBaseline: (String name) {
        return DynamicWidgetData._textBaselineMap[name.toLowerCase()]
            ?? TextBaseline.alphabetic;
      } (map["text_baseline"] ?? ""),
    );
  }
}

class DynamicWidgetData {

  final int id;
  final int parentId;
  final String configName;
  final String widgetType;
  final int depth;
  final int flex;
  final int widgetOrder;

  final double? width;
  final double? height;

  final String uniqueName;

  final EdgeInsets padding;
  final Color? color;
  final Alignment alignment;

  final TextStyle? textStyle;

  final double? posLeft;
  final double? posRight;
  final double? posTop;
  final double? posBottom;

  final List<DynamicWidgetData> _children = [];

  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final TextBaseline textBaseline;

  bool get isRoot => depth == 1 && parentId == 0;
  bool get isSingle => parentId == -1;

  bool get isCaption => widgetType == "Caption";
  bool get isData => widgetType == "Data";
  bool get isButton => widgetType == "Button";

  static late final Map<String, MainAxisAlignment> _mainAxisAlignmentMap
  = Map.fromEntries(MainAxisAlignment.values.map((ali) => MapEntry(ali.name.toLowerCase(), ali)));

  static late final Map<String, CrossAxisAlignment> _crossAxisAlignmentMap
  = Map.fromEntries(CrossAxisAlignment.values.map((ali) => MapEntry(ali.name.toLowerCase(), ali)));

  static late final Map<String, TextBaseline> _textBaselineMap
  = Map.fromEntries(TextBaseline.values.map((line) => MapEntry(line.name.toLowerCase(), line)));

  static Color? parseColor(StringMap map, {
    String fieldA = "background_a",
    String fieldR = "background_r",
    String fieldG = "background_g",
    String fieldB = "background_b",
  }) {
    final a = int.tryParse(map[fieldA] ?? "") ?? -1;
    final r = int.tryParse(map[fieldR] ?? "") ?? -1;
    final g = int.tryParse(map[fieldG] ?? "") ?? -1;
    final b = int.tryParse(map[fieldB] ?? "") ?? -1;
    return (a < 0 && r < 0 && g < 0 && b < 0)
      ? null
      : Color.fromARGB(a, r, g, b);
  }

  DynamicWidgetData({
    required this.id,
    required this.parentId,
    required this.configName,
    required this.widgetType,
    required this.depth,
    required this.flex,
    required this.widgetOrder,

    required this.uniqueName,

    required this.padding,
    required this.color,
    required this.alignment,

    this.width,
    this.height,

    this.textStyle,

    this.posLeft,
    this.posRight,
    this.posTop,
    this.posBottom,

    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textBaseline = TextBaseline.alphabetic,
  });

  void clear() {
    for (final child in _children) {
      child.clear();
    }
    _children.clear();
  }
}

typedef DynamicWidgetBuilder = Widget Function(
  String configName,
  DynamicWidgetData widgetData,
  StringMap data,
  Widget child,
);

class DynamicWidget extends StatelessWidget {

  final String configName;

  ///
  final DynamicWidgetData widgetData;

  ///
  final DynamicWidgetData parentWidgetData;

  final StringMap data;

  /// Called when [widgetData.widgetType] is neither 'Stack', 'Column' and 'Row'
  final DynamicWidgetBuilder builder;

  /// When given [configName] cannot locate any [DynamicWidgetData] tree
  final Widget Function(BuildContext) defaultBuilder;

  const DynamicWidget._({
    required this.configName,
    required this.widgetData,
    required this.parentWidgetData,
    required this.data,
    required this.builder,
    required this.defaultBuilder,
  });

  factory DynamicWidget.root({
    required String configName,
    StringMap data = const {},
    required DynamicWidgetBuilder builder,
    required Widget Function(BuildContext) defaultBuilder,
  }) => DynamicWidget._(
    configName: configName,
    widgetData: DynamicWidgetManager().get(configName) ?? DynamicWidgetManager().defaultValue,
    parentWidgetData: DynamicWidgetManager().defaultValue,
    data: data,
    builder: builder,
    defaultBuilder: defaultBuilder,
  );

  String get parentWidgetType => parentWidgetData.widgetType;
  String get widgetType => widgetData.widgetType;

  bool get parentIsColRow => parentWidgetType == "Column" || parentWidgetType == "Row";
  bool get parentIsStack => parentWidgetType == "Stack";

  @override
  Widget build(BuildContext context) {
    // No DynamicWidgetData tree is found
    if (widgetData == DynamicWidgetManager().defaultValue) {
      return defaultBuilder(context);
    }

    final childrenData = widgetData._children;

    Widget child;
    if (widgetType == "Stack") {
      child = childrenData.isNotEmpty
        ? Stack(children: childrenData.map(buildChildWidget).toList())
        : Container();
    } else if (widgetType == "Column") {
      child = childrenData.isNotEmpty
        ? Column(
            mainAxisAlignment: widgetData.mainAxisAlignment,
            crossAxisAlignment: widgetData.crossAxisAlignment,
            textBaseline: widgetData.textBaseline,
            children: childrenData.map(buildChildWidget).toList()
          )
        : Container();
    } else if (widgetType == "Row") {
      child = childrenData.isNotEmpty
        ? Row(
            mainAxisAlignment: widgetData.mainAxisAlignment,
            crossAxisAlignment: widgetData.crossAxisAlignment,
            textBaseline: widgetData.textBaseline,
            children: childrenData.map(buildChildWidget).toList()
          )
        : Container();
    } else {
      child = builder(
        configName,
        widgetData,
        data,
        childrenData.isNotEmpty
          ? buildChildWidget(childrenData.first)
          : Container()
      );
    }

    child = Container(
      padding: widgetData.padding,
      width: widgetData.width,
      height: widgetData.height,
      color: widgetData.color,
      alignment: widgetData.alignment,
      child: child
    );

    /* The earlier version uses ||
     * Potential hazard
     **/
    if (parentIsColRow && widgetData.flex > 0) {
      child = Expanded(flex: widgetData.flex, child: child);
    } else if (parentIsStack) {
      child = Positioned(
        left: widgetData.posLeft,
        right: widgetData.posRight,
        top: widgetData.posTop,
        bottom: widgetData.posBottom,
        child: child,
      );
    }

    if (widgetData.textStyle != null) {
      child = DefaultTextStyle(
        style: widgetData.textStyle!,
        child: child
      );
    }

    return child;
  }

  DynamicWidget buildChildWidget(DynamicWidgetData childData) {
    return DynamicWidget._(
      configName: configName,
      widgetData: childData,
      parentWidgetData: widgetData, // Self
      data: data,
      builder: builder,
      defaultBuilder: defaultBuilder,
    );
  }
}