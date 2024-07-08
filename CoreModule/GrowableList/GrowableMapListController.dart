
part of growable_controller;

abstract class GrowableMapListController<T extends GCDelegate, I> extends GrowableController<T, I> {

  GrowableMapListController({
    required super.delegate,
    required super.request,
    required super.itemFactory,
    required super.itemHashCodeProvider,
  });

  final Map<String, List<GCItem<I>>> _dataSource = {};
  @override get isEmpty => _dataSource.isEmpty;

  final List<String> _keyList = [];
  Iterable<String> get keyList => _keyList;
  int get keyCount => _keyList.length;

  int listLength(String key) => _dataSource[key]?.length ?? 0;

  String keyAt(int idx) => _keyList[idx];

  @override
  GCItem<I>? getItem(GCItemLocation loc) {
    if (!loc.isValid) { return null; }
    return _dataSource[loc.key]![loc.idx];
  }

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

  /// Get a Map<String, List<GCItem> from the [WebApiResult] and add it into _dataSource
  /// Duplicated records will be removed according to the value of field $uniqueName
  @override
  void insert(WebApiResult webApiResult) {
    Set<int> setHashCode = {};
    final otherSource = webApiResult.asMapListStringMap(
      fieldName: request.sqlDisplayName,
    ).map((key, list) => MapEntry(key, list.map(itemFactory).toList()));

    final arrEntry = otherSource.entries.toList();

    int length = arrEntry.length;
    for (int i = 0; i < length; i++) {
      if (_dataSource[arrEntry[i].key] == null) {
        _dataSource[arrEntry[i].key] = arrEntry[i].value;
      } else {
        _dataSource[arrEntry[i].key]!.addAll(arrEntry[i].value);

        // Guarantee that each map in list has unique value for 'uniqueField'
        _dataSource[arrEntry[i].key]!.retainWhere((e) => setHashCode.add(itemHashCodeProvider(e)));

        print(_dataSource[arrEntry[i].key]!.length);
      }
      setHashCode.clear();
    }

    // Insert keys
    Set<String> setKeyHashCode = {};
    final otherKeyList = webApiResult.getKeyList(fieldName: request.sqlDisplayName);
    _keyList.addAll(otherKeyList);
    _keyList.retainWhere(setKeyHashCode.add);

    super.insert(webApiResult);
  }

  void _update(Map<String, List<GCItem>> other, GCItemPredicate predicate) {
    if (other.isEmpty) { return; }
    String key = other.keys.first;
    List<GCItem> list = other[key]!;
    if (list.isEmpty) { return; }
    GCItem model = list.first;
    int index = _dataSource[key]!.indexWhere(predicate);
    if (index != -1) {
      // _dataSource[key]![index] = model;
    }
  }

  /// Delete the item match predicate (typically, isCurrent)
  /// Then set curr to next item.
  /// If no locatable item is available, curr will be set to null
  @override
  void _delete(bool Function(GCItem<I>) predicate) {
    MapEntry<String, List<GCItem<I>>>? prev, curr, next;
    GCItem<I>? loc;
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

  @override
  int dataSourceCount(WebApiResult webApiResult) {
    final mapList = webApiResult.asMapListStringMap(fieldName: request.sqlDisplayName);
    int result = 0;
    for (final list in mapList.values) {
      result += list.length;
    }
    return result;
  }
}