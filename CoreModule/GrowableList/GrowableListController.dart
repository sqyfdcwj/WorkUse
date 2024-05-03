
part of growable_controller;

abstract class GrowableListController<T extends GCDelegate, I> extends GrowableController<T, I> {

  GrowableListController({
    required super.delegate,
    required super.request,
    required super.itemFactory,
    required super.itemHashCodeProvider,
  });

  final List<GCItem<I>> _dataSource = [];

  @override get isEmpty => _dataSource.isEmpty;
  @override get firstItem => _dataSource.isNotEmpty ? _dataSource.first : null;
  @override get lastItem => _dataSource.isNotEmpty ? _dataSource.last : null;
  @override get elementCount => _dataSource.length;

  @override
  GCItem<I>? getItem(GCItemLocation loc) {
    if (!loc.isValid) { return null; }
    return _dataSource[loc.idx];
  }

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
    _dataSource.addAll(webApiResult.asListStringMap(
      fieldName: request.sqlDisplayName,
    ).map(itemFactory));
    _dataSource.retainWhere((e) => setHashCode.add(itemHashCodeProvider(e)));
    super.insert(webApiResult);
  }

  @override
  void _delete(bool Function(GCItem<I>) predicate) {
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

  @override
  int dataSourceCount(WebApiResult webApiResult) {
    final list = webApiResult.asListStringMap(fieldName: request.sqlDisplayName);
    return list.length;
  }
}