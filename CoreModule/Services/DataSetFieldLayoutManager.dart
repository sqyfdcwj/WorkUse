
import 'package:flutter/material.dart';
import '../Export.dart';

class DataSetFieldLayoutManager extends SingleTypeManagerBootstrap<DataSetFieldLayout>
  with SingleTypeManagerBootstrapMapMixin<DataSetFieldLayout> {

  DataSetFieldLayoutManager._();
  static final _instance = DataSetFieldLayoutManager._();
  factory DataSetFieldLayoutManager() => _instance;

  @override final DataSetFieldLayout defaultValue = const DataSetFieldLayout(
    uniqueName: "",
    layoutType: 0,  // Single value
    captionFlex: 1,
    contentFlex: 1,
    captionAlignment: Alignment.topLeft,
    contentAlignment: Alignment.topLeft,
    hideOnEmpty: true,
    captionTextStyle: null,
    contentTextStyle: null,
  );

  @override final String sourceFieldName = "dataset_field_layout_list";
  @override final String uniqueField = "unique_name";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getDatasetFieldLayout);

  @override
  DataSetFieldLayout getFromMap(StringMap map) {
    return DataSetFieldLayout(
      uniqueName: map["unique_name"] ?? "",
      layoutType: int.tryParse(map["layout_type"] ?? "1") ?? 1,
      captionFlex: int.tryParse(map["caption_flex"] ?? "1") ?? 1,
      contentFlex: int.tryParse(map["content_flex"] ?? "1") ?? 1,
      captionAlignment: Alignment(
        double.tryParse(map["caption_alignment_x"] ?? "-1") ?? -1,
        double.tryParse(map["caption_alignment_y"] ?? "-1") ?? -1,
      ),
      contentAlignment: Alignment(
        double.tryParse(map["content_alignment_x"] ?? "-1") ?? -1,
        double.tryParse(map["content_alignment_y"] ?? "-1") ?? -1,
      ),
      hideOnEmpty: int.tryParse(map["hide_on_empty"] ?? "0") == 1,
      captionTextStyle: TextStyleManager().getFromMap(map),
      // contentTextStyle: null,
    );
  }


}

class DataSetFieldLayout {

  final String uniqueName;

  /// 0 - Data only
  /// 1 - Caption & Data (Row)
  /// 2 - Caption & Data (Column)
  final int layoutType;

  final int captionFlex;
  final int contentFlex;
  final Alignment? captionAlignment;
  final Alignment? contentAlignment;
  final bool hideOnEmpty;

  final TextStyle? captionTextStyle;
  final TextStyle? contentTextStyle;

  const DataSetFieldLayout({
    required this.uniqueName,
    required this.layoutType,
    required this.captionFlex,
    required this.contentFlex,
    this.captionAlignment,
    this.contentAlignment,
    required this.hideOnEmpty,
    this.captionTextStyle,
    this.contentTextStyle,
  });
}


class DataSetField extends StatelessWidget {

  final SqlGroupName sqlGroupName;
  final String sqlDisplayName;
  final String fieldName;
  final String content;
  final TextStyle? defaultCaptionTextStyle;
  final TextStyle? defaultContentTextStyle;
  final Alignment? defaultContentAlignment;

  ///
  const DataSetField({
    super.key,
    required this.sqlGroupName,
    required this.sqlDisplayName,
    required this.fieldName,
    required this.content,
    this.defaultCaptionTextStyle,
    this.defaultContentTextStyle,
    this.defaultContentAlignment,
  });

  @override
  Widget build(BuildContext context) {

    final uniqueName = tspMgr.getUniqueName(
      sqlGroupName.name,
      sqlDisplayName,
      fieldName
    );

    /// Get DataSetFieldLayout instance

    final layout = DataSetFieldLayoutManager().get(uniqueName)
      ?? DataSetFieldLayoutManager().defaultValue;

    if (layout.hideOnEmpty && content.isEmpty) {
      return Container();
    }

    // Call TextStylePredicateManager().getTextStyle to get the style with the content
    final contentTextStyle = tspMgr.getTextStyle(uniqueName, content);

    Widget dataField = DataField(
      alignment: layout.contentAlignment ?? defaultContentAlignment,
      textStyle: contentTextStyle ?? layout.contentTextStyle ?? defaultContentTextStyle,
      content: content
    );

    if (layout.layoutType == 1) {
      // Row (caption field + data field)
      Widget captionField = CaptionField(
        uniqueName: layout.uniqueName,
        alignment: layout.captionAlignment,
        defaultTextStyle: layout.captionTextStyle
      );
      if (layout.captionFlex > 0) {
        captionField = Expanded(flex: layout.captionFlex, child: captionField);
      }
      if (layout.contentFlex > 0) {
        dataField = Expanded(flex: layout.contentFlex, child: dataField);
      }
      return Row(children: [ captionField, dataField ]);
    } else if (layout.layoutType == 2) {
      // Column (caption field + data field)
      return Column(children: [
        CaptionField(
          uniqueName: layout.uniqueName,
          alignment: layout.captionAlignment,
          defaultTextStyle: layout.captionTextStyle
        ),
        dataField,
      ]);
    } else {
      return dataField;   // Single (data field only)
    }
  }
}

class CaptionField extends StatelessWidget {

  final Alignment? alignment;
  final String uniqueName;
  final String defaultValue;
  final TextStyle? defaultTextStyle;

  const CaptionField({
    super.key,
    required this.uniqueName,
    this.alignment,
    this.defaultTextStyle,
    this.defaultValue = "",
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: captMgr.curLang,
      builder: (context, lang, child) {
        return DataField(
          alignment: alignment,
          content: captMgr.getCaption(uniqueName, lang: lang) ?? defaultValue,
          textStyle: defaultTextStyle
        );
      }
    );
  }
}

/// A Text
class DataField extends StatelessWidget {

  final Alignment? alignment;

  final String content;
  final TextStyle? textStyle;

  const DataField({
    super.key,
    required this.alignment,
    required this.content,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      child: Text(content, style: textStyle)
    );
  }
}