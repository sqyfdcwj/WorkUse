
part of growable_controller;

/// The term GC is the abbr of GrowableController

/// Params used by GrowableController and its descendant classes
/// Used to construct the
class GCParam extends ChangeNotifier {

  Map<String, dynamic> get snap => _fields.map((k, v) => MapEntry(k, v.snap));
  Map<String, String?> get asStringMap => _fields.map((k, v) => MapEntry(k, v.asString()));

  bool get modified => _fixedFields.values.any((f) => f.snap != f.init);

  final Map<String, GCParamFixed> _fixedFields = {};
  final Map<String, GCParamType> _fields = {};
  final bool shouldTriggerWhenNull;

  factory GCParam.empty({
    bool shouldTriggerWhenNull = false,
  }) => GCParam(fields: [], shouldTriggerWhenNull: shouldTriggerWhenNull);

  GCParam({
    List<GCParamType> fields = const [],
    this.shouldTriggerWhenNull = false,
  }) {
    for (final field in fields) {
      _add(field);
    }
  }

  void addAuto(GCParamTypeAuto field) => _add(field);

  void _add(GCParamType field) {
    _fields[field.name] = field;
    field._parent = this;
    if (field is GCParamFixed) {
      _fixedFields[field.name] = field;
    }
  }

  GCParamType? getField(String name) => _fields[name];

  void commit() {
    _fixedFields.forEach((_, f) => f.commit());
    notifyListeners();
  }

  void rollback() => _fixedFields.forEach((_, f) => f.rollback());
}

abstract class GCParamType<T> {

  String name;
  GCParam? _parent;
  GCParam? get parent => _parent;

  T? get init;
  T? get real;
  T? get snap;

  String? asString();

  GCParamType(this.name);
}

abstract class GCParamFixed<T> extends GCParamType<T> {

  @override GCParam? get parent => _parent;

  T? _init;
  @override T? get init => _init;

  T? _real;
  @override T? get real => _real;

  @override T? snap;

  GCParamFixed(super.name, { T? init }) {
    _init = init;
    _real = init;
    snap = init;
  }

  void commit() {
    _real = snap;
  }

  void rollback() {
    snap = _real;
  }

  void reset() {
    _real = init;
    snap = init;
  }

  void onChanged(T? newValue) {
    snap = newValue;
  }
}


class GCParamString extends GCParamFixed<String> {

  GCParamString(super.name, { super.init });

  @override String? asString() => snap;
}

class GCParamBool extends GCParamFixed<bool> {

  GCParamBool(super.name, { super.init });

  @override String? asString() {
    if (snap == null) {
      return null;
    } else if (snap!) {
      return "1";
    } else {
      return "0";
    }
  }
}

class GCParamDateTime extends GCParamFixed<DateTime> {

  final DateFormat dateFormat;
  final bool isDate;
  final DateTime? firstDate;
  final int? firstDateOffset;
  final DateTime? lastDate;
  final int? lastDateOffset;

  GCParamDateTime(super.name, {
    super.init,
    String dateFmt = "yyyy-MM-dd",
    this.isDate = true,
    this.firstDate,
    this.firstDateOffset,
    this.lastDate,
    this.lastDateOffset,
  }): dateFormat = DateFormat(dateFmt);

  DateTime? get validFirstDate {
    if (!isDate) {
      return null;
    }
    return firstDate ?? (firstDateOffset != null ? DateTime.now().subtract(Duration(days: firstDateOffset!)) : null);
  }

  DateTime? get validLastDate {
    if (!isDate) {
      return null;
    }
    final result = lastDate ?? (lastDateOffset != null ? DateTime.now().subtract(Duration(days: lastDateOffset!)) : null);
    return result != null && (validFirstDate == null || !result.isBefore(validFirstDate!))
      ? result
      : null;
  }

  @override asString() {
    try {
      return snap == null ? null : dateFormat.format(snap!);
    } catch (_) {
      return null;
    }
  }
}

abstract class GCParamTypeAuto<T> extends GCParamType<T> {

  GCParamTypeAuto(super.name, { required this.convert });
  String? Function(T?) convert;

  @override String? asString() => convert(snap);

  @override T? get init => snap;
  @override T? get real => snap;
}

class GCParamValueNotifier<T> extends GCParamTypeAuto<T> {

  final ValueNotifier<T?> _vn;

  GCParamValueNotifier(super.name, {
    required ValueNotifier<T?> vn,
    required super.convert,
  }): _vn = vn;

  @override T? get snap => _vn.value;
}

class GCParamValueGetter<T> extends GCParamTypeAuto<T> {

  final T? Function() _vn;

  GCParamValueGetter(super.name, {
    required T? Function() fn,
    required super.convert,
  }): _vn = fn;

  @override T? get snap => _vn.call();
}