
part of bootstrap;

class Bootstrap {

  Bootstrap._() { reset(); }
  static final _instance = Bootstrap._();
  factory Bootstrap() => _instance;

  /// A list of BootstrapEntry which is to be executed
  final List<BootstrapEntry> _queue = [];

  void add(BootstrapImpl impl) {
    if (_queue.any((entry) => entry.impl == impl)) {
      return;
    }
    _queue.add(BootstrapEntry(impl));
  }

  void remove(BootstrapImpl impl) {
    _queue.removeWhere((entry) => entry.impl == impl);
  }

  void removeAllFail() {
    _queue.removeWhere((entry) => entry.execTime > 0 && !entry.isSuccess);
  }

  void printBootstrap() {
    for (final boot in _queue) {
      print(boot.impl.runtimeType.toString());
    }
  }

  void clear() => _queue.clear();

  void reset() {
    clear();
    add(LocalStorage());
    add(AppConfigManager());
    add(DataSourceManager());
    add(CaptionManager());
    add(DataSetFieldLayoutManager());
    add(DynamicWidgetManager());
    add(TextStyleManager());
    add(TextStylePredicateManager());
  }

  /// Return a list of BootstrapEntry executed
  Future<List<BootstrapEntry>> exec({
    bool isFailOnly = true,
    bool isRemoveOnSuccess = false
  }) async {
    /// List of bootstrap entries to be executed
    /// If isFailOnly, then filter ones which isSuccess == false
    /// Otherwise all entries will be executed
    final beList = _queue.where((entry) {
      return isFailOnly ? !entry.isSuccess : true;
    }).toList();

    /// Bootstrap entry result list
    final brList = await Future.wait<void>(beList.map((entry) async {
      await entry.init();
      // return entry;
    })); 

    /// Sort by their complete time
    beList.sort((lhs, rhs) => lhs.endTime!.isAfter(rhs.endTime!) ? 1 : 0);

    if (isRemoveOnSuccess) {
      removeAllFail();
    }
    return beList;
  }
}