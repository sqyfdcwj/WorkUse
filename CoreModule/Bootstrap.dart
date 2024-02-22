
import 'Export.dart';

class Bootstrap {

  Bootstrap._();
  static final _instance = Bootstrap._();
  factory Bootstrap() => _instance;

  final List<BootstrapImpl> _coreModuleList = [
    AppConfigManager(),
    CaptionManager(),
    DataSourceManager(),
    DataSetFieldLayoutManager(),
    DynamicWidgetManager(),
    TextStyleManager(),
    TextStylePredicateManager(),
  ];

  final Map<int, BootstrapImpl> _bootstrapMap = {};

  void add(BootstrapImpl impl) {
    _bootstrapMap[impl.hashCode] = impl;
  }

  void remove(BootstrapImpl impl) {
    _bootstrapMap.remove(impl.hashCode);
  }

  Future<void> init() async {
    /// Execute every impl.init(). If isInit is true, remove this from the map
    await Future.wait(_bootstrapMap.values.map((impl) {
      return impl.init().then((_) {
        if (impl.isInit) {
          print("${impl.runtimeType.toString()} init");
          remove(impl);
        } else {
          print("${impl.runtimeType.toString()} unfinished");
        }
      });
    }));
  }

  Future<void> initForce() async {
    for (final coreModule in _coreModuleList) {
      add(coreModule);
    }
    return init();
  }

  Future<void> initUnfinished() async {
    for (final coreModule in _coreModuleList) {
      if (!coreModule.isInit) {
        add(coreModule);
      }
    }
    return init();
  }
}

abstract class BootstrapImpl {

  bool isInit = false;
  Future<void> init() async {}
}

abstract class ManagerBootstrap<T> extends BootstrapImpl {

  T get defaultValue;

  T? get(String name);
  T getNonNull(String name) => get(name) ?? defaultValue;
  T getFromMap(Map<String, String> map);

  String get sourceFieldName;
  String get uniqueField;

  Future<WebApiResult> get webApiRequest;

  @override
  Future<void> init() async {
    clearData();
    final webApiResult = await webApiRequest;
    isInit = initWithWebApiResult(webApiResult);
    return super.init();
  }

  /// Initialize the data structure with [WebApiResult] instance
  bool initWithWebApiResult(WebApiResult webApiResult);

  Future<bool> initFromLocal() async {
    return false;
  }

  /// Clear the data structure which holds all <T> instances.
  void clearData();
}

abstract class ManagerBootstrapMap<T> extends ManagerBootstrap<T> {

  final Map<String, T> dataMap = {};

  @override T? get(String name) => dataMap[name];

  /// Default implementation
  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!webApiResult.isSuccess) {
      return false;
    }
    final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
    for (final map in list) {
      dataMap[map[uniqueField] ?? ""] = getFromMap(map);
    }
    return true;
  }

  @override
  void clearData() => dataMap.clear();
}


abstract class ManagerBootstrapList<T> extends ManagerBootstrap<T> {

  final List<T> dataList = [];

  /// Default implementation
  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!webApiResult.isSuccess) {
      return false;
    }
    final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
    dataList.addAll(list.map(getFromMap));
    return true;
  }

  @override
  void clearData() => dataList.clear();
}