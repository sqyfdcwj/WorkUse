
part of growable_controller;

typedef StringMapPredicate = bool Function(StringMap);
typedef UniqueIdProvider = int Function(StringMap);

typedef GCItemPredicate = bool Function(GCItem);

typedef PredicateFuture = Future<bool?> Function();
typedef ObjectPredicateFuture = Future<bool?> Function(Object);
typedef GCParamPredicateFuture = Future<bool?> Function(GCParam);

typedef WebApiRequest = Future<WebApiResult> Function();
typedef WebApiResultPredicateFuture = Future<bool?> Function(WebApiResult);

/// A data structure which holds GCItem

abstract class GrowableController<T extends GCDelegate, I> extends ChangeNotifier {

  // We cannot declare [dataSource] in this class because [List] and [Map] has no common ancestors.
  // It is declared in [GrowableListController] and [GrowableMapListController]
  final T delegate;
  final GCRequest request;
  GCParam get requestParam => request.param;

  final GCItem<I> Function(StringMap) itemFactory;
  final int Function(GCItem<I>) itemHashCodeProvider;

  GrowableController({
    required this.delegate,
    required this.request,
    required this.itemFactory,
    required this.itemHashCodeProvider,
  }) { registerCallback(); }

  /// Get a GCItem<I> with GCItemLocation. Return null if not found.
  GCItem<I>? getItem(GCItemLocation loc);

  final ValueNotifier<GCState> currentState = ValueNotifier(GCState.success);
  bool get isSuccess => currentState.value == GCState.success;
  bool get isFail => currentState.value == GCState.fail;
  bool get isDownloading => currentState.value == GCState.downloading;
  bool get isFinished => currentState.value == GCState.finished;

  /// The record selected by the user currently
  final ValueNotifier<GCItem<I>?> current = ValueNotifier(null);
  final ValueNotifier<bool> canLoadMore = ValueNotifier(false);

  /// Must be implemented by descendant class
  GCItem<I>? get firstItem;

  /// Must be implemented by descendant class
  GCItem<I>? get lastItem;

  GCItem<I>? get currentItem => current.value;
  int get elementCount;
  bool get isEmpty => elementCount == 0;
  bool get isNotEmpty => !isEmpty;

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

  @mustCallSuper
  void clear() {
    print("${runtimeType.toString()} clear $hashCode");
    notifyListeners();
  }

  Future<void> configureParam() async {
    final result = await delegate.onConfigureParam?.call(request.param);
    if (result ?? request.param.shouldTriggerWhenNull) {
      request.param.commit();
      return await onReachMin();
    } else {
      request.param.rollback();
    }
  }

  /// Exposed to be used by [GrowableStickyList]
  /// When a scrollable list has reached its top and want to reload the list
  Future<void> onReachMin() async {
    canLoadMore.value = true; // Reset
    print("${runtimeType.toString()} onReachMin $hashCode");
    _cancelLocate();
    clear();  // This will not trigger delegate.onEmptyDataSource
    return await onReachMax();
  }

  /// Exposed to be used by [GrowableStickyList]
  /// When a scrollable list has reached its bottom and want to load more records
  Future<void> onReachMax() async {
    if (!canLoadMore.value) {
      return;
    }
    canLoadMore.value = false;
    bool isEmptyBefore = isEmpty;

    currentState.value = GCState.downloading;
    final webApiResult = await request.exec();
    currentState.value = GCState.finished;

    if (webApiResult.isError) {
      _onWebApiResultError(webApiResult);
    } else if (webApiResult.isTimeout) {
      _onWebApiResultTimeout(webApiResult);
    } else {
      _onWebApiResultSuccess(webApiResult, isEmptyBefore);
    }
  }

  Future<void> _onWebApiResultError(WebApiResult webApiResult) async {
    currentState.value = GCState.fail;
    await delegate.onFail(webApiResult);
  }

  Future<void> _onWebApiResultTimeout(WebApiResult webApiResult) async {
    currentState.value = GCState.fail;
    await delegate.onFail(webApiResult);
    canLoadMore.value = true;
  }

  Future<void> _onWebApiResultSuccess(WebApiResult webApiResult, bool isEmptyBefore) async {
    int otherElementCount = dataSourceCount(webApiResult);
    await _onWebApiResult(webApiResult);
    canLoadMore.value = otherElementCount >= webApiRequestPageSize;
    currentState.value = GCState.success;
    if (isEmpty) {
      // If the dataSource is still empty after insert
      await delegate.onEmptyDataSource();
    } else if (isEmptyBefore) {
      await _locateFirst();
    }
    notifyListeners();
  }

  int dataSourceCount(WebApiResult webApiResult);

  /// Calling this function is meaningless when WebApiResult::isSuccess is false
  Future<void> _onWebApiResult(WebApiResult webApiResult) async {
    assert(webApiResult.isSuccess);
    insert(webApiResult);
  }

  /// This function is not exposed.
  /// Set current.value to null. This will trigger listeners of current
  Future<void> _cancelLocate() async {
    print("${runtimeType.toString()} cancelLocate");
    current.value = null;
  }

  Future<void> _locateFirst() async {
    print("${runtimeType.toString()} locateFirst");
    current.value = firstItem;
  }

  /// Delete the current focused record from dataSource
  /// If current is not null then _delete is performed. Override this function to add guard actions.
  Future<void> deleteCurrent() async {
    if (current.value != null) {
      _delete(isCurrent);
      notifyListeners();  // Notify listeners to refresh UI
      if (isEmpty) {
        await delegate.onEmptyDataSource();
      }
    }
  }

  /// This method is called by onWebApiResult(), and must be implemented by the descendant class
  /// because this method involves dataSource manipulation and the dataSource type is unknown in this class.
  @mustCallSuper
  void insert(WebApiResult webApiResult) {
    insertExtra(webApiResult);
  }

  void insertExtra(WebApiResult webApiResult) { }

  /// This method is called by _deleteCurrent(), and must be implemented by the descendant class
  /// because this method involves dataSource manipulation and the dataSource type is unknown in this class.
  void _delete(bool Function(GCItem<I>) predicate);

  bool isCurrent(GCItem<I>? rhs) {
    return rhs != null && current.value != null
        && itemHashCodeProvider(current.value!) == itemHashCodeProvider(rhs);
  }
}