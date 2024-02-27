
import 'package:flutter/material.dart';
import '../CoreModule/Export.dart';

typedef DataPredicate = bool Function<Data>(Data);
typedef IdProvider = int Function<Data>(Data);

abstract class GrowableController<Container, Data> extends ChangeNotifier {

  final Future<WebApiResult> Function() webApiRequest;
  final String sqlDisplayName;

  GrowableController({
    required this.webApiRequest,
    required Container dataSource,
    required this.sqlDisplayName,
  }) : _dataSource = dataSource;

  final Container _dataSource;
  Container get dataSource => _dataSource;

  Data? get firstItem;
  Data? get lastItem;
  int get elementCount;

  void _clear();

  void _insert(Container other);

  void _update(Container other, DataPredicate predicate);

  void _delete(DataPredicate predicate);

  void locate(Data? data);

  Future<void> onReachMin() async {
    _clear();
    notifyListeners();  // Some UI works
    return onReachMax();
  }

  Future<void> onReachMax() async {
    final webApiResult = await webApiRequest();
    notifyListeners();  // Some UI works
    return;
  }

  void _onWebApiResult(WebApiResult webApiResult);
}

abstract class GrowableListController
  extends GrowableController<List<Map<String, String>>, Map<String, String>> {

  GrowableListController({
    required super.webApiRequest,
    required super.sqlDisplayName,
  }): super(
    dataSource: const <Map<String, String>>[]
  );

  @override get firstItem => _dataSource.isNotEmpty ? _dataSource.first : null;
  @override get lastItem => _dataSource.isNotEmpty ? _dataSource.last : null;
  @override get elementCount => _dataSource.length;

  @override
  void _clear() {
    _dataSource.clear();
    notifyListeners();
  }
}

abstract class GrowableMapListController
  extends GrowableController<
    Map<String, List<Map<String, String>>>,
    Map<String, String>
  > {

  GrowableMapListController({
    required super.webApiRequest,
    required super.sqlDisplayName,
  }): super(
    dataSource: const <String, List<Map<String, String>>>{}
  );

  final List<String> _dataSourceKeyList = [];

  String? get firstKey => _dataSourceKeyList.isNotEmpty ? _dataSourceKeyList.first : null;
  String? get lastKey => _dataSourceKeyList.isNotEmpty ? _dataSourceKeyList.last : null;

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
  void _clear() {
    _dataSourceKeyList.clear();
    _dataSource.clear();
    notifyListeners();
  }

  @override
  void _insert(Map<String, List<Map<String, String>>> other) {
    Set<int> setHashCode = {};
    final arrEntry = other.entries.toList();  // List<MapEntry<String, ListStringMap>>
    int length = arrEntry.length;
    for (int i = 0; i < length; i++) {
      if (dataSource[arrEntry[i].key] == null) {
        dataSource[arrEntry[i].key] = arrEntry[i].value;
      } else {
        dataSource[arrEntry[i].key]!.addAll(arrEntry[i].value);

        /// Guarantee that each map in list has unique value for 'uniqueField'
        dataSource[arrEntry[i].key]!.retainWhere((e) => setHashCode.add(_idProvider(e)));
      }
      setHashCode.clear();
    }
  }

  @override
  void _update(Map<String, List<Map<String, String>>> other, DataPredicate predicate) {
    if (other.isEmpty) { return; }
    String key = other.keys.first;
    List<Map<String, String>> list = other[key]!;
    if (list.isEmpty) { return; }
    Map<String, String> model = list.first;
    int index = dataSource[key]!.indexWhere(predicate);
    if (index != -1) {
      dataSource[key]![index] = model;
    } else {
      log("GrowableListController::updateItem This element does not exist in datasource");
    }
  }

  @override
  void _delete(DataPredicate predicate) {
    dataSource.removeWhere((key, list) {
      list.removeWhere(predicate);
      if (list.isEmpty) {
        _dataSourceKeyList.removeWhere((element) => element == key);
      }
      return list.isEmpty;  // If true, the entry will be removed
    });
  }

  void _insertKey(List<String> other) {
    Set<String> setHashCode = {};
    _dataSourceKeyList.addAll(other);
    _dataSourceKeyList.retainWhere(setHashCode.add);
  }

  int _idProvider(Map<String, String> map) => map[""].hashCode;

  @override
  void _onWebApiResult(WebApiResult webApiResult) {
    assert(webApiResult.isSuccess);
    _insert(webApiResult.asMapListStringMap(fieldName: sqlDisplayName));
    _insertKey(webApiResult.getKeyListFromBody(fieldName: sqlDisplayName));
  }
}

class PL extends GrowableMapListController {

  PL({required super.webApiRequest, required super.sqlDisplayName});



  void _deleteAndRelocate(DataPredicate predicate) {
    MapEntry<String, List<Map<String, String>>>? prevEntry;
    MapEntry<String, List<Map<String, String>>>? currEntry;
    MapEntry<String, List<Map<String, String>>>? nextEntry;
    Map<String, String>? loc;
    final dataSourceEntryLength = dataSource.entries.length;
    for (int i = 0; i < dataSourceEntryLength; i++) {
      prevEntry = i == 0 ? null : dataSource.entries.elementAt(i - 1);
      currEntry = dataSource.entries.elementAt(i);
      nextEntry = i == dataSourceEntryLength - 1 ? null : dataSource.entries.elementAt(i + 1);

      // +++++++++++++++++++++++++   +++++++++   +++++
      // | 1 | 2         | 3     |   | 4 | 5 |   | 6 |
      // +++++++++++++++++++++++++   +++++++++   +++++
      // | a | b | c | d | e | f |   | g | h |   | i |
      // +++++++++++++++++++++++++   +++++++++   +++++
      final targetIdx = currEntry.value.indexWhere(predicate);
      final isNotFirst = targetIdx > 0;
      final isNotLast = targetIdx != currEntry.value.length - 1;
      if (targetIdx != -1) {
        if (!isNotLast && nextEntry != null && nextEntry.value.isNotEmpty) {
          // Elements satisfied with this cond: a / d / g
          // Locate the first element in their next entry, which is b / e / h
          loc = nextEntry.value.first;
        } else if (isNotLast) {
          // Elements satisfied with this cond: b / c / e
          // Locate their next element, which is c / d / f
          loc = currEntry.value.elementAt(targetIdx + 1);
        } else if (isNotFirst) {
          // Elements satisfied with this cond: f
          // Locate their prev element, which is e
          loc = currEntry.value.elementAt(targetIdx - 1);
        } else if (!isNotFirst && prevEntry != null && prevEntry.value.isNotEmpty) {
          // Elements satisfied with this cond: h
          // Locate the last element in their prev entry, which is g
          loc = prevEntry.value.last;
        } else {
          // Elements satisfied with this cond: i
          // There is no locatable element. Locate null
          loc = null;
        }

        currEntry.value.removeAt(targetIdx);
        if (currEntry.value.isEmpty) {
          // Remove the entry if value becomes empty
          _dataSourceKeyList.removeWhere((key) => key == currEntry!.key);
          _dataSource.remove(currEntry.key);
        }
        // This method is called by POListState::submit
        // After calling this method, openDtl will be called and it will call locate
        // So we pass false to shouldNotify to avoid rebuild twice
        // _locate(loc, shouldNotify: true);
        locate(loc);
        return;
      }
    }
  }

  @override
  void locate(Map<String, String>? data) {

  }
}