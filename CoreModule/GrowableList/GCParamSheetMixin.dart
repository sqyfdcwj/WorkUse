
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'GCInclude.dart';

abstract class GCParamSheet extends StatefulWidget {

  final GCParam param;
  const GCParamSheet({ super.key, required this.param });
}

mixin GCParamSheetMixin<T extends GCParamSheet> on State<T> {

  final formBuilderKey = GlobalKey<FormBuilderState>();
  FormBuilderState get formBuilderState => formBuilderKey.currentState!;
  Map<String, dynamic> get formBuilderValue => formBuilderState.instantValue;

  EdgeInsets get contentPadding => const EdgeInsets.symmetric(horizontal: 20, vertical: 5);// eiH20V5;

  GCParam get param => widget.param;
  TextStyle get defaultTextStyle => const TextStyle(fontSize: 18);

  final outlineInputBorder = OutlineInputBorder(
    borderSide: const BorderSide(width: 2),
    borderRadius: BorderRadius.circular(20)
  );

  WidgetBuilder get builder;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formBuilderKey,
      child: Builder(builder: builder)
    );
  }

  Widget btnReset(String name) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => formBuilderState.fields[name]?.didChange(param.getField(name)?.init),
    );
  }

  Widget buildFieldWithName(String name) => buildField(param.getField(name));

  Widget buildField(GCParamType? info, {
    InputDecoration? decoration,
    TextStyle style = const TextStyle(fontSize: 18),
    TextAlignVertical? textAlignVertical = TextAlignVertical.center,
    int? minLines,
    int? maxLines,
  }) {
    if (info == null) {
      return Container();
    }
    Widget result;
    if (info is GCParamString) {
      result = buildTextField(info,
        decoration: decoration,
        style: style,
        textAlignVertical: textAlignVertical,
        minLines: minLines,
        maxLines: maxLines,
      );
    } else if (info is GCParamBool) {
      result = buildCheckbox(info);
    } else if (info is GCParamDateTime) {
      result = info.isDate
        ? buildDatePicker(info, decoration: decoration, style: style)
        : buildTimePicker(info, decoration: decoration, style: style);
    } else {
      result = Container();
    }
    return result;
  }

  FormBuilderTextField buildTextField(GCParamString info, {
    InputDecoration? decoration,
    TextStyle style = const TextStyle(fontSize: 18),
    TextAlignVertical? textAlignVertical = TextAlignVertical.center,
    int? minLines,
    int? maxLines,
  }) {
    return FormBuilderTextField(
      name: info.name,
      decoration: decoration ?? getInputDecoration(info.name),
      style: style,
      textAlignVertical: textAlignVertical,
      initialValue: info.snap,
      onChanged: info.onChanged,
      minLines: minLines,
      maxLines: maxLines,
    );
  }

  FormBuilderCheckbox buildCheckbox(GCParamBool info) {
    return FormBuilderCheckbox(
      name: info.name,
      title: const Text(""),
      initialValue: info.snap,
      onChanged: info.onChanged,
    );
  }

  FormBuilderDateTimePicker buildDatePicker(GCParamDateTime info, {
    InputDecoration? decoration,
    TextStyle style = const TextStyle(fontSize: 18),
  }) {
    return FormBuilderDateTimePicker(
      name: info.name,
      format: info.dateFormat,
      decoration: decoration ?? getInputDecoration(info.name),
      style: style,
      inputType: InputType.date,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: DateTime.now(),
      firstDate: info.validFirstDate,
      lastDate: info.validLastDate,
      initialValue: info.snap,
      onChanged: info.onChanged,
    );
  }

  FormBuilderDateTimePicker buildTimePicker(GCParamDateTime info, {
    InputDecoration? decoration,
    TextStyle style = const TextStyle(fontSize: 18),
  }) {
    return FormBuilderDateTimePicker(
      name: info.name,
      format: info.dateFormat,
      decoration: decoration ?? getInputDecoration(info.name),
      style: style,
      inputType: InputType.date,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: DateTime.now(),
      firstDate: info.validFirstDate,
      lastDate: info.validLastDate,
      initialValue: info.snap,
      onChanged: info.onChanged,
    );
  }

  InputDecoration getInputDecoration(String name) {
    return InputDecoration(
      isDense: true,
      contentPadding: contentPadding,
      border: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      suffixIcon: btnReset(name),
    );
  }

  void reset() {
    for (final fieldName in formBuilderState.fields.keys) {
      formBuilderState.fields[fieldName]?.didChange(null);
    }
  }
}