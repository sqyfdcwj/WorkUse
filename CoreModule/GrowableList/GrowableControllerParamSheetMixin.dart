
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'GrowableController.dart';

abstract class GrowableControllerParamSheet extends StatefulWidget {

  const GrowableControllerParamSheet({ super.key });
}

abstract class GrowableControllerParamSheetState extends State<GrowableControllerParamSheet>
  with GrowableControllerParamSheetMixin {

}

mixin GrowableControllerParamSheetMixin on State<GrowableControllerParamSheet> {

  final formBuilderKey = GlobalKey<FormBuilderState>();
  FormBuilderState get formBuilderState => formBuilderKey.currentState!;
  Map<String, dynamic> get formBuilderValue => formBuilderState.instantValue;

  final dateFormat = DateFormat("yyyy-MM-dd");
  EdgeInsets get contentPadding => const EdgeInsets.symmetric(horizontal: 20, vertical: 5);// eiH20V5;

  GrowableControllerParam get param;
  Map<String, dynamic> get paramSnapshot => param.paramSnapshot;

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
      onPressed: () => formBuilderState.fields[name]?.didChange(null),
    );
  }

  Widget buildField(GrowableControllerParamInfo info) {
    Widget result;
    switch (info.type.toLowerCase()) {
      case "string":
        result = FormBuilderTextField(
          name: info.name,
          decoration: getInputDecoration(info.name),
          style: defaultTextStyle,
          textAlignVertical: TextAlignVertical.center,
          initialValue: paramSnapshot[info.name],
          onChanged: (val) => paramSnapshot[info.name] = val,
        );
        break;
      case "date":
        result = FormBuilderDateTimePicker(
          name: info.name,
          format: dateFormat,
          decoration: getInputDecoration(info.name),
          style: defaultTextStyle,
          inputType: InputType.date,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: DateTime.now(),
          firstDate: info.validFirstDate,
          lastDate: info.validLastDate,
          initialValue: _tryParseDate(paramSnapshot[info.name]),
          onChanged: (dateTime) => paramSnapshot[info.name] = _tryFormatDate(dateTime),
        );
        break;
      case "time":
        result = FormBuilderDateTimePicker(
          name: info.name,
          decoration: getInputDecoration(info.name),
          style: defaultTextStyle,
          inputType: InputType.time,
          onChanged: (dateTime) => paramSnapshot[info.name] = _tryFormatDate(dateTime),
        );
        break;
      case "boolean":
        result = FormBuilderCheckbox(
          name: info.name,
          title: const Text(""),
          initialValue: (paramSnapshot[info.name] ?? "0") != "0",
          onChanged: (val) => paramSnapshot[info.name] = val == null ? null : val ? "1" : "0"
        );
        break;
      default:
        return Container();
    }
    return result;
    // return Padding(
    //   padding: const EdgeInsets.only(bottom: 5),
    //   child: Row(children: [
    //     Expanded(child: Text(paramField.name)),
    //     Expanded(child: result),
    //   ])
    // );
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

  //

  void reset() {
    for (final fieldName in formBuilderState.fields.keys) {
      formBuilderState.fields[fieldName]?.didChange(null);
    }
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null) {
      return null;
    }
    try {
      return dateFormat.parse(value);
    } catch (_) {
      return null;
    }
  }

  String? _tryFormatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    try {
      return dateFormat.format(value);
    } catch (_) {
      return null;
    }
  }
}