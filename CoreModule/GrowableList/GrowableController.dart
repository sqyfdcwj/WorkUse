
import 'package:flutter/material.dart';
import '../Export.dart';

typedef StringMapPredicate = bool Function(StringMap);
typedef UniqueIdProvider = int Function(StringMap);

/// A set of callbacks used by the GrowableController
class GrowableControllerDelegate {

  /// Used by class [GrowableController] and its derived class
  final String sqlDisplayName;
  final String uniqueName;

  final UniqueIdProvider? uniqueIdProvider;

  final Future<WebApiResult> Function() webApiRequest;

  /// A function that most likely to pop a UI for user to confirm
  final Future<bool?> Function(GrowableControllerParam)? onConfigureParam;

  /// Triggered when one of following is satisfied:
  /// 1. dataSource is empty and no dataSource can be obtained from WebApiResult
  /// 2. dataSource becomes empty after called _delete
  ///
  /// By default, calling clear() will not trigger this callback.
  final Future<bool> Function() onEmptyDataSource;

  /// Triggered when a WebApiResult failed.
  /// This method returns a boolean so the method who called this method can
  /// decide whether to exit.
  final Future<bool> Function(WebApiResult) onFail;

  /// Triggered when notifyListener() is called
  final VoidCallback? onNotifyListener;

  /// Triggered when value of currentState changed
  final VoidCallback? onCurrentStateChanged;

  /// Triggered when value of current changed
  final VoidCallback? onCurrentChanged;

  GrowableControllerDelegate({
    required this.sqlDisplayName,
    required this.uniqueName,
    required this.webApiRequest,
    Future<bool> Function()? onEmptyDataSource,
    Future<bool> Function(WebApiResult)? onFail,
    this.uniqueIdProvider,
    this.onNotifyListener,
    this.onCurrentChanged,
    this.onCurrentStateChanged,
    this.onConfigureParam,
  }): onEmptyDataSource = onEmptyDataSource ?? dlg.handleDataSourceEmpty,
      onFail = onFail ?? dlg.handleWebApiResultOnFail;
}

class GrowableControllerParamInfo {

  final String name;
  final String type;

  /// Used when [type] is "date"
  final String? dateFormat;

  /// When [type] is "date", this field is used to construct a constant date lower bound in a date range
  final DateTime? firstDate;

  /// When [type] is "date", this field is used to construct a constant date upper bound in a date range
  final DateTime? lastDate;

  /// When [type] is "date" and [firstDate] is not set,
  /// this field is then used to construct a date lower bound in a date range = today - Duration(firstDateOffset)
  final int? firstDateOffset;

  /// When [type] is "date" and [lastDate] is not set,
  /// this field is then used to construct a date lower bound in a date range = today - Duration(firstDateOffset)
  final int? lastDateOffset;

  GrowableControllerParamInfo._(this.name, this.type, {
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.firstDateOffset,
    this.lastDateOffset,
  });

  factory GrowableControllerParamInfo.string(String name) => GrowableControllerParamInfo._(name, "string");
  factory GrowableControllerParamInfo.boolean(String name) => GrowableControllerParamInfo._(name, "boolean");
  factory GrowableControllerParamInfo.date(String name, {
    String? dateFormat,
    DateTime? firstDate,
    DateTime? lastDate,
    int? firstDateOffset,
    int? lastDateOffset,
  }) => GrowableControllerParamInfo._(name,
    "date",
    dateFormat: dateFormat,
    firstDate: firstDate,
    lastDate: lastDate,
    firstDateOffset: firstDateOffset,
    lastDateOffset: lastDateOffset,
  );

  bool get isString => type.toLowerCase() == "string";
  bool get isBoolean => type.toLowerCase() == "boolean";
  bool get isDate => type.toLowerCase() == "date";

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
}

class GrowableControllerParam {

  final Map<String, dynamic> _param = {};
  late final Map<String, dynamic> paramSnapshot = {};

  final List<GrowableControllerParamInfo> _paramList = [];
  Iterable<GrowableControllerParamInfo> get paramList => _paramList;
  final bool shouldTriggerWhenNull;

  factory GrowableControllerParam.empty({
    bool shouldTriggerWhenNull = false,
  }) => GrowableControllerParam(raw: [], shouldTriggerWhenNull: shouldTriggerWhenNull);

  GrowableControllerParam({
    required List<GrowableControllerParamInfo> raw,
    this.shouldTriggerWhenNull = false,
  }) {
    Set<String> nameSet = {};
    raw.retainWhere((info) => nameSet.add(info.name));
    _paramList.addAll(raw);
    final otherMap = Map.fromEntries(_paramList.map((info) => MapEntry(info.name, null)));
    _param.addAll(otherMap);
  }

  void commit() {
    print("${runtimeType.toString()} Commit");
    _param.clear();
    _param.addAll(paramSnapshot);
  }

  void rollback() {
    print("${runtimeType.toString()} Rollback");
    paramSnapshot.clear();
    paramSnapshot.addAll(_param);
  }
}

enum GrowableControllerState {

  /// The [GrowableController] will enter this state before it calls
  /// [GrowableControllerDelegate::webApiRequest] to perform network request
  /// The listener can do some UI work here (e.g. display a loading progress bar)
  downloading,

  /// This is a transient state
  /// The [GrowableController] will enter this state when it has just finished the network request
  /// The listener can do some UI work here (e.g dismiss the loading progress bar)
  /// After that, the state will be switched to [GrowableControllerState.success]
  /// or [GrowableControllerState.fail] depending on the WebApiResult
  finished,

  /// This state indicates that the last WebApiRequest is successful
  /// The listener can do some UI work here (e.g. refresh the UI)
  success,

  /// This state indicates that the last WebApiRequest failed
  /// The listener can do some UI work here (e.g. refresh the UI)
  fail,
}

abstract class GrowableController<T extends GrowableControllerDelegate> extends ChangeNotifier {

  // We cannot declare [dataSource] in this class because [List] and [Map] has no common ancestors.
  // It is declared in [GrowableListController] and [GrowableMapListController]
  final T delegate;
  final GrowableControllerParam param;
  GrowableController({ required this.delegate, required this.param }) { registerCallback(); }

  final ValueNotifier<GrowableControllerState> currentState = ValueNotifier(GrowableControllerState.success);

  bool get isSuccess => currentState.value == GrowableControllerState.success;
  bool get isFail => currentState.value == GrowableControllerState.fail;
  bool get isDownloading => currentState.value == GrowableControllerState.downloading;
  bool get isFinished => currentState.value == GrowableControllerState.finished;

  /// The record selected by the user currently
  final ValueNotifier<StringMap?> current = ValueNotifier(null);

  @override
  void dispose() {
    unregisterCallback();
    super.dispose();
  }

  void registerCallback() {
    if (delegate.onNotifyListener != null) {
      addListener(delegate.onNotifyListener!);
    }
    if (delegate.onCurrentChanged != null) {
      current.addListener(delegate.onCurrentChanged!);
    }
    if (delegate.onCurrentStateChanged != null) {
      currentState.addListener(delegate.onCurrentStateChanged!);
    }
  }

  void unregisterCallback() {
    if (delegate.onNotifyListener != null) {
      removeListener(delegate.onNotifyListener!);
    }
    if (delegate.onCurrentChanged != null) {
      current.removeListener(delegate.onCurrentChanged!);
    }
    if (delegate.onCurrentStateChanged != null) {
      currentState.removeListener(delegate.onCurrentStateChanged!);
    }
  }

  StringMap? get firstItem;

  StringMap? get lastItem;

  int get elementCount;

  bool get isEmpty => elementCount == 0;

  @mustCallSuper
  void clear() {
    print("${runtimeType.toString()} clear $hashCode");
    notifyListeners();
  }

  Future<void> configureParam() async {
    final result = await delegate.onConfigureParam?.call(param);
    if (result ?? param.shouldTriggerWhenNull) {
      param.commit();
      return await onReachMin();
    } else {
      param.rollback();
    }
  }

  /// Exposed to be used by [GrowableStickyList]
  /// When a scrollable list has reached its top and want to reload the list
  Future<void> onReachMin() async {
    print("${runtimeType.toString()} onReachMin $hashCode");
    cancelLocate();
    clear();
    return await onReachMax();
  }

  /// Exposed to be used by [GrowableStickyList]
  /// When a scrollable list has reached its bottom and want to load more records
  Future<void> onReachMax() async {
    print("${runtimeType.toString()} onReachMax $hashCode");
    bool isEmptyBefore = isEmpty;

    currentState.value = GrowableControllerState.downloading;
    final webApiResult = await delegate.webApiRequest();
    currentState.value = GrowableControllerState.finished;


    if (!webApiResult.isSuccess) {
      currentState.value = GrowableControllerState.fail;
      await delegate.onFail(webApiResult);
      return;
    } else {
      await onWebApiResult(webApiResult);
      currentState.value = GrowableControllerState.success;
      bool isEmptyAfter = isEmpty;
      if (isEmptyAfter) {
        // If the dataSource is still empty after insert
        print("${runtimeType.toString()} isEmpty, Empty");
        await delegate.onEmptyDataSource();
      } else if (isEmptyBefore) {
        await locateFirst();
      }
      notifyListeners();
    }
  }

  /// Calling this function is meaningless when WebApiResult::isSuccess is false
  Future<void> onWebApiResult(WebApiResult webApiResult) async {
    assert(webApiResult.isSuccess);
    insert(webApiResult);
  }

  Future<void> cancelLocate() async {
    print("${runtimeType.toString()} cancelLocate");
    current.value = null;
  }

  Future<void> locateFirst() async {
    print("${runtimeType.toString()} locateFirst");
    current.value = firstItem;
  }

  /// Delete the current focused record from dataSource
  /// If current is not null then _delete is performed. Override this function to add guard actions.
  Future<void> deleteCurrent() async {
    if (current.value != null) {
      _delete(isCurrent);
      notifyListeners();
      if (isEmpty) {
        await delegate.onEmptyDataSource();
      }
    }
  }

  /// This method is called by onWebApiResult(), and must be implemented by the descendant class
  /// because this method involves dataSource manipulation and the dataSource type is unknown in this class.
  void insert(WebApiResult webApiResult);

  /// This method is called by _deleteCurrent(), and must be implemented by the descendant class
  /// because this method involves dataSource manipulation and the dataSource type is unknown in this class.
  void _delete(StringMapPredicate predicate);

  bool isCurrent(StringMap? d) => d != null && current.value == d;

  int idProvider(StringMap map) => map[delegate.uniqueName].hashCode;
}

class GrowableListController<T extends GrowableControllerDelegate> extends GrowableController<T> {

  GrowableListController({ required super.delegate, required super.param });

  final ListStringMap _dataSource = [];

  @override get isEmpty => _dataSource.isEmpty;
  @override get firstItem => _dataSource.isNotEmpty ? _dataSource.first : null;
  @override get lastItem => _dataSource.isNotEmpty ? _dataSource.last : null;
  @override get elementCount => _dataSource.length;

  int indexOf(StringMap map) => _dataSource.indexOf(map);
  StringMap elementAt(int idx) => _dataSource[idx];

  @override
  void clear() {
    _dataSource.clear();
    super.clear();
  }

  /// Get a ListStringMap from the [WebApiResult] and add it into _dataSource
  /// Duplicated records will be removed according to the value of field $uniqueName
  /// This method should be override by descendant class if it needs to do extra work with the [WebApiResult]
  @override
  void insert(WebApiResult webApiResult) {
    Set<int> setHashCode = {};
    _dataSource.addAll(webApiResult.asListStringMap(fieldName: delegate.sqlDisplayName));
    _dataSource.retainWhere((e) => setHashCode.add(idProvider(e)));
  }

  @override
  void _delete(StringMapPredicate predicate) {
    final idx = _dataSource.indexWhere(predicate);  // -1 when not found
    if (idx == -1) {
      return;
    }
    final hasPrev = idx > 0;
    final hasNext = idx < _dataSource.length - 1;
    if (hasNext) {
      current.value = _dataSource[idx + 1];
    } else if (hasPrev) {
      current.value = _dataSource[idx - 1];
    } else {
      current.value = null;
    }
    _dataSource.removeAt(idx);
  }
}

class GrowableMapListController<T extends GrowableControllerDelegate> extends GrowableController<T> {

  GrowableMapListController({ required super.delegate, required super.param });

  final MapListStringMap _dataSource = {};
  @override get isEmpty => _dataSource.isEmpty;

  final List<String> _keyList = [];
  Iterable<String> get keyList => _keyList;
  int get keyCount => _keyList.length;
  String keyAt(int index) => _keyList[index];
  int listLength(String key) => _dataSource[key]?.length ?? 0;
  StringMap elementAt(String key, int idx) => _dataSource[key]![idx];

  String? get firstKey => _keyList.isNotEmpty ? _keyList.first : null;
  String? get lastKey => _keyList.isNotEmpty ? _keyList.last : null;

  @override get firstItem => firstKey != null && _dataSource[firstKey] != null
    ? _dataSource[firstKey]!.first
    : null;

  @override get lastItem => lastKey != null && _dataSource[lastKey] != null
    ? _dataSource[lastKey]!.last
    : null;

  @override
  int get elementCount {
    int result = 0;
    for (final entry in _dataSource.entries) {
      result += entry.value.length;
    }
    return result;
  }

  @override
  void clear() {
    _keyList.clear();
    _dataSource.clear();
    super.clear();
  }

  /// Get a MapListStringMap from the [WebApiResult] and add it into _dataSource
  /// Duplicated records will be removed according to the value of field $uniqueName
  @override
  void insert(WebApiResult webApiResult) {
    // Insert dataSource
    Set<int> setHashCode = {};
    final otherSource = webApiResult.asMapListStringMap(fieldName: delegate.sqlDisplayName);
    final arrEntry = otherSource.entries.toList();  // List<MapEntry<String, ListStringMap>>
    int length = arrEntry.length;
    for (int i = 0; i < length; i++) {
      if (_dataSource[arrEntry[i].key] == null) {
        _dataSource[arrEntry[i].key] = arrEntry[i].value;
      } else {
        _dataSource[arrEntry[i].key]!.addAll(arrEntry[i].value);

        // Guarantee that each map in list has unique value for 'uniqueField'
        _dataSource[arrEntry[i].key]!.retainWhere((e) => setHashCode.add(idProvider(e)));
      }
      setHashCode.clear();
    }

    // Insert keys
    Set<String> setKeyHashCode = {};
    final otherKeyList = webApiResult.getKeyList(fieldName: delegate.sqlDisplayName);
    _keyList.addAll(otherKeyList);
    _keyList.retainWhere(setKeyHashCode.add);
  }

  void _update(MapListStringMap other, StringMapPredicate predicate) {
    if (other.isEmpty) { return; }
    String key = other.keys.first;
    ListStringMap list = other[key]!;
    if (list.isEmpty) { return; }
    StringMap model = list.first;
    int index = _dataSource[key]!.indexWhere(predicate);
    if (index != -1) {
      _dataSource[key]![index] = model;
    }
  }

  @override
  void _delete(StringMapPredicate predicate) {
    MapEntry<String, ListStringMap>? prev, curr, next;
    StringMap? loc;
    final dataSourceEntryLength = _dataSource.entries.length;
    for (int i = 0; i < dataSourceEntryLength; i++) {
      prev = i == 0 ? null : _dataSource.entries.elementAt(i - 1);
      curr = _dataSource.entries.elementAt(i);
      next = i == dataSourceEntryLength - 1 ? null : _dataSource.entries.elementAt(i + 1);

      // List1                       List2       List3
      // +++++++++++++++++++++++++   +++++++++   +++++
      // | 1 | 2         | 3     |   | 4 | 5 |   | 6 |
      // +++++++++++++++++++++++++   +++++++++   +++++
      // | a | b | c | d | e | f |   | g | h |   | i |
      // +++++++++++++++++++++++++   +++++++++   +++++
      final targetIdx = curr.value.indexWhere(predicate);  // -1 when not found
      final isNotFirst = targetIdx > 0;
      final isNotLast = targetIdx != curr.value.length - 1;

      // If found, delete and locate next
      if (targetIdx != -1) {
        if (!isNotLast && next != null && next.value.isNotEmpty) {
          // Elements satisfied with this cond: a / d / g
          // Locate the first element in their next entry, which is b / e / h
          loc = next.value.first;
        } else if (isNotLast) {
          // Elements satisfied with this cond: b / c / e
          // Locate their next element, which is c / d / f
          loc = curr.value.elementAt(targetIdx + 1);
        } else if (isNotFirst) {
          // Elements satisfied with this cond: f
          // Locate their prev element, which is e
          loc = curr.value.elementAt(targetIdx - 1);
        } else if (!isNotFirst && prev != null && prev.value.isNotEmpty) {
          // Elements satisfied with this cond: h
          // Locate the last element in their prev entry, which is g
          loc = prev.value.last;
        } else {
          // Elements satisfied with this cond: i
          // There is no locatable element. Locate null
          loc = null;
        }

        // Delete element
        curr.value.removeAt(targetIdx);
        if (curr.value.isEmpty) {
          // Also remove the list if it becomes empty after deleted the element
          _keyList.removeWhere((key) => key == curr!.key);
          _dataSource.remove(curr.key);
        }

        current.value = loc;  // Auto locate next element
        break; // Exit the loop
      }
    }
  }
}