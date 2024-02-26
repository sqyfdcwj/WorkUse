

import 'dart:convert';

import 'package:flutter/material.dart';
import '../Constants/FieldNameConstant.dart';
import '../Constants/TypeDef.dart';
import '../CoreModule/Export.dart';

/// Any class derived from this class should call webApiResultProvider()
/// with [sqlGroupName] to get a [WebApiResult] in its concrete logic,
/// then read a List or Map<String, List> from the [WebApiResult]
/// using [sqlDisplayName] and [uniqueField]
abstract class GrowableController extends ChangeNotifier {

  final SqlGroupName sqlGroupName;
  final String sqlDisplayName;
  final String uniqueField;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;
  void _setIsDownloading(bool newValue) {
    _isDownloading = newValue;
    notifyListeners();
  }

  int get elementCount;

  bool _disposed = false;
  bool get disposed => _disposed;

  GrowableController({
    required this.sqlGroupName,
    required this.sqlDisplayName,
    required this.uniqueField,
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Template method
  Future<WebApiResult> downloadData() async {
    _setIsDownloading(true);
    final webApiResult = await webApiResultProvider();
    onGetWebApiResult(webApiResult);
    _setIsDownloading(false);

    return webApiResult;
  }

  Future<WebApiResult> webApiResultProvider();

  void onGetWebApiResult(WebApiResult webApiResult) {}

  void clearDataSource() => notifyListeners();
}

mixin SearchTextMixin on GrowableController {

  String searchTxt = "";
}

/// This class is reserved for StatefulWidget GrowableList use. See GrowableList.dart
/// So far this class has no derived class because GrowableList is not used
abstract class GrowableListController extends GrowableController {

  GrowableListController({
    required super.sqlGroupName,
    required super.sqlDisplayName,
    required super.uniqueField,
  });
}

/// This class and its derived classes are used by GrowableStickyList
/// See GrowableStickyList.dart
///
/// This class uses Map<String, List> as datasource type,
/// and has a List<String> arrDataSourceKey to record the order of keys
abstract class GrowableStickyListController extends GrowableController {

  GrowableStickyListController({
    required super.sqlGroupName,
    required super.sqlDisplayName,
    required super.uniqueField,
  });

  final MapListStringMap dataSource = {};
  final List<String> arrDataSourceKey = [];

  StringMap? get firstItem {
    if (firstKey == null || dataSource[firstKey] == null) { return null; }
    return dataSource[firstKey]!.first;
  }

  StringMap? get lastItem {
    if (lastKey == null || dataSource[lastKey] == null) { return null; }
    return dataSource[lastKey]!.last;
  }

  String get firstRowId => firstItem?[fnRowId] ?? "0";
  String get lastRowId => lastItem?[fnRowId] ?? "0";
  String? get firstKey => arrDataSourceKey.isNotEmpty ? arrDataSourceKey.first: null;
  String? get lastKey => arrDataSourceKey.isNotEmpty ? arrDataSourceKey.last: null;

  @override
  int get elementCount {
    int result = 0;
    for (final entry in dataSource.entries) {
      result += entry.value.length;
    }
    return result;
  }

  @override
  void clearDataSource() {
    dataSource.clear();
    arrDataSourceKey.clear();
    super.clearDataSource();
  }

  @override
  void onGetWebApiResult(WebApiResult webApiResult) {
    insertItem(
      other: webApiResult.asMapListStringMap(fieldName: sqlDisplayName),
    );
    insertKey(other: webApiResult.getKeyListFromBody(fieldName: sqlDisplayName));
  }

  /// Map with same value in uniqueField returns same hashCode
  int idProvider(StringMap map) => (map[uniqueField] ?? "").hashCode;

  /// Template method. No need to be override by derived class
  void insertItem({
    required MapListStringMap other,
  }) {
    Set<int> setHashCode = {};
    final arrEntry = other.entries.toList();  // List<MapEntry<String, ListStringMap>>
    int length = arrEntry.length;
    for (int i = 0; i < length; i++) {
      if (dataSource[arrEntry[i].key] == null) {
        dataSource[arrEntry[i].key] = arrEntry[i].value;
      } else {
        dataSource[arrEntry[i].key]!.addAll(arrEntry[i].value);

        /// Guarantee that each map in list has unique value for 'uniqueField'
        dataSource[arrEntry[i].key]!.retainWhere((e) => setHashCode.add(idProvider(e)));
      }
      setHashCode.clear();
    }
  }

  void updateItem({
    required MapListStringMap map,
    required bool Function(StringMap) predicate,
  }) {
    if (map.isEmpty) { return; }
    String key = map.keys.first;
    ListStringMap list = map[key]!;
    if (list.isEmpty) { return; }
    StringMap model = list.first;
    int index = dataSource[key]!.indexWhere(predicate);
    if (index != -1) {
      dataSource[key]![index] = model;
    } else {
      log("GrowableListController::updateItem This element does not exist in datasource");
    }
  }

  /// Remove item from dataSource
  void deleteItem({
    required bool Function(StringMap) predicate,
  }) {
    dataSource.removeWhere((key, list) {
      list.removeWhere(predicate);
      if (list.isEmpty) {
        arrDataSourceKey.removeWhere((element) => element == key);
      }
      return list.isEmpty;  // If true, the entry will be removed
    });
  }

  void insertKey({ required List<String> other }) {
    Set<String> setHashCode = {};
    arrDataSourceKey.addAll(other);
    arrDataSourceKey.retainWhere(setHashCode.add);
  }
}

abstract class ProviderStickyListController extends GrowableStickyListController {

  ProviderStickyListController({
    required super.sqlGroupName,
    required super.sqlDisplayName,
    required super.uniqueField,
  });

  StringNMap param = {};
  ValueNotifier<StringMap?> current = ValueNotifier({});

  StringMap? search(bool Function(StringMap) predicate) {
    for (final list in dataSource.values) {
      for (final val in list) {
        if (predicate(val)) {
          return val;
        }
      }
    }
    return null;
  }

  void locate(StringMap? map, { bool shouldNotify = true }) {
    current.value = map;
    if (shouldNotify) {
      notifyListeners();
    }

  }

  void removeWithRowId(String rowId) {
    deleteItem(predicate: (map) {
      if (map[fnRowId] == null) {
        return false;
      }
      return map[fnRowId] == rowId;
    });
  }
}

class GenericProviderListController extends ProviderStickyListController {

  final StringNMap Function()? paramProvider;

  final List<void Function(StringMap?)> onLocate = [];

  GenericProviderListController({
    required super.sqlGroupName,
    required super.sqlDisplayName,
    required super.uniqueField,
    this.paramProvider,
  });

  @override
  Future<WebApiResult> webApiResultProvider() {
    final map = <String, String?>{};
    map.addAll(param);
    final other = paramProvider?.call();
    if (other != null) {
      map.addAll(other);
    }
    map.addAll({ fnRowId: lastRowId });
    log(jsonEncode(map));
    return WebApi().postSingle(
      sqlGroupName: sqlGroupName,
      param: map
    );
  }

  /// Override super.removeWithRowId
  /// Remove the rowId and auto locates next / prev object
  @override
  void removeWithRowId(String rowId) {
    MapEntry<String, ListStringMap>? prevEntry;
    MapEntry<String, ListStringMap>? currEntry;
    MapEntry<String, ListStringMap>? nextEntry;
    StringMap? loc;
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
      final targetIdx = currEntry.value.indexWhere((map) => map[fnRowId] != null && map[fnRowId] == rowId);
      final isNotFirst = targetIdx > 0;
      final isNotLast = targetIdx != currEntry.value.length - 1;
      if (targetIdx != -1) {
        if (!isNotLast && nextEntry != null && nextEntry.value.isNotEmpty) {
          // Elements satisfied with this cond: a / d / g
          // Locate the first element in their next entry, which is b / e / h
          log("case 1");
          loc = nextEntry.value.first;
        } else if (isNotLast) {
          // Elements satisfied with this cond: b / c / e
          // Locate their next element, which is c / d / f
          log("case 2");
          loc = currEntry.value.elementAt(targetIdx + 1);
        } else if (isNotFirst) {
          // Elements satisfied with this cond: f
          // Locate their prev element, which is e
          log("case 3");
          loc = currEntry.value.elementAt(targetIdx - 1);
        } else if (!isNotFirst && prevEntry != null && prevEntry.value.isNotEmpty) {
          // Elements satisfied with this cond: h
          // Locate the last element in their prev entry, which is g
          log("case 4");
          loc = prevEntry.value.last;
        } else {
          // Elements satisfied with this cond: i
          // There is no locatable element. Locate null
          log("case 5");
          loc = null;
        }

        currEntry.value.removeAt(targetIdx);
        if (currEntry.value.isEmpty) {
          // Remove the entry if value becomes empty
          arrDataSourceKey.removeWhere((key) => key == currEntry!.key);
          dataSource.remove(currEntry.key);
        }
        // This method is called by POListState::submit
        // After calling this method, openDtl will be called and it will call locate
        // So we pass false to shouldNotify to avoid rebuild twice
        locate(loc, shouldNotify: true);
        return;
      }
    }
  }
}