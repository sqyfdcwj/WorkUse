
import 'Export.dart';

class Bootstrap {

  Bootstrap._() { _coreModuleList.forEach(add); }
  static final _instance = Bootstrap._();
  factory Bootstrap() => _instance;

  final List<BootstrapImpl> _coreModuleList = [
    LocalStorage(),
    AppConfigManager(),
    CaptionManager(),
    DataSourceManager(),
    DataSetFieldLayoutManager(),
    DynamicWidgetManager(),
    TextStyleManager(),
    TextStylePredicateManager(),
  ];

  final Map<int, _BootstrapEntry> _bootstrapMap = {};

  void add(BootstrapImpl impl) {
    if (_bootstrapMap.containsKey(impl.hashCode)) {
      return;
    }
    _bootstrapMap[impl.hashCode] = _BootstrapEntry(impl);
  }

  void remove(BootstrapImpl impl) {
    _bootstrapMap.remove(impl.hashCode);
  }

  Future<dynamic> init() async {
    /// Execute every impl.init(). If isInit is true, remove this from the map
    // await Future.wait(_bootstrapMap.values.map((impl) {
    //   return impl.init().then((_) {
    //     if (impl.isInit) {
    //       print("${impl.runtimeType.toString()} init");
    //       remove(impl);
    //     } else {
    //       print("${impl.runtimeType.toString()} unfinished");
    //     }
    //   });
    // }));
    return Future.wait(_bootstrapMap.values.where((v) => !v.isInit).map((boot) => boot.init()));
  }

  Future<dynamic> initForce() async {
    return Future.wait(_bootstrapMap.values.map((boot) => boot.initForce()));
    // for (final coreModule in _coreModuleList) {
    //   add(coreModule);
    // }
    // return init();
  }

  // Future<void> initUnfinished() async {
  //   // for (final coreModule in _coreModuleList) {
  //   //   if (!coreModule.isInit) {
  //   //     add(coreModule);
  //   //   }
  //   // }
  //   return init();
  // }
}

class _BootstrapEntry {

  bool isInit = false;
  void reset() => isInit = false;

  Future<void> init() async {
    isInit = await impl.init();
    return;
  }

  Future<void> initForce() async {
    reset();
    return init();
  }

  BootstrapImpl impl;
  _BootstrapEntry(this.impl);
}

abstract class BootstrapImpl {

  Future<bool> init() async => true;
}

abstract class ManagerBootstrap<T> extends BootstrapImpl {

  Future<WebApiResult> get webApiRequest;

  @override
  Future<bool> init() async {
    clearData();
    final webApiResult = await webApiRequest;

    // Try to init data from WebApiResult, if false, init data from local
    bool result = initWithWebApiResult(webApiResult);
    if (!result) {
      result = await initFromLocal();
    }
    return result;
  }

  /// Initialize the data structure with [WebApiResult] instance
  bool initWithWebApiResult(WebApiResult webApiResult) {
    return webApiResult.isSuccess;
  }

  Future<bool> initFromLocal() async { return true; }

  /// Clear the data structure which holds all <T> instances.
  void clearData();
}

/// A Manager class that stores 1 type
/// The data structure is unknown in this class and it is implemented by mixin:
/// SingleTypeManagerBootstrapMapMixin, where data structure is Map<String, T>, and
/// SingleTypeManagerBootstrapListMixin, where data structure is List<T>
abstract class SingleTypeManagerBootstrap<T> extends ManagerBootstrap<T> {

  T get defaultValue;

  T? get(String name);
  T getNonNull(String name) => get(name) ?? defaultValue;
  T getFromMap(Map<String, String> map);

  String get sourceFieldName;
  String get uniqueField;
}

mixin SingleTypeManagerBootstrapMapMixin<T> on SingleTypeManagerBootstrap<T> {

  final Map<String, T> dataMap = {};

  @override T? get(String name) => dataMap[name];
  @override void clearData() => dataMap.clear();

  /// Default implementation
  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!super.initWithWebApiResult(webApiResult)) { return false; }
    final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
    for (final map in list) {
      dataMap[map[uniqueField] ?? ""] = getFromMap(map);
    }
    return true;
  }
}

mixin SingleTypeManagerBootstrapListMixin<T> on SingleTypeManagerBootstrap<T> {

  final List<T> dataList = [];
  @override void clearData() => dataList.clear();

  /// Default implementation
  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!super.initWithWebApiResult(webApiResult)) { return false; }
    final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
    dataList.addAll(list.map(getFromMap));
    return true;
  }
}