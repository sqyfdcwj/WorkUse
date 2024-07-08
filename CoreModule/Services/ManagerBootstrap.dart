
import '../Bootstrap/Export.dart';
import '../WebApi.dart';

/// This class is the base class of Manager class
/// The manager class has a data structure which holds type T
/// We cannot assert the concrete type of the data structure
/// It can be Map<String, List<T>> or List<T>
abstract class ManagerBootstrap<T> extends BootstrapImpl {

  Future<WebApiResult> get webApiRequest;

  @override
  Future<String?> init() async {
    print("${runtimeType.toString()}::init");

    clearData();

    // Try to load data from local assets, which returns null by default
    final localResult = await initFromLocal();

    // After loaded local data, try to load remote data, which may override local data
    final remoteResult = await initFromRemote();

    if (remoteResult == null) {
      return null;
    } else {
      return localResult;
    }
  }

  ///
  Future<String?> initFromRemote() async {
    final webApiResult = await webApiRequest;
    return initWithWebApiResult(webApiResult);
  }

  /// Init the data structure with [WebApiResult] instance
  /// Override this function in descendant class to add behavior
  /// when webApiResult is successful.
  String? initWithWebApiResult(WebApiResult webApiResult) {
    if (webApiResult.isSuccess) {
      return null;
    } else {
      if (webApiResult.isConnectTimeout) {
        return "Connection timeout";
      } else if (webApiResult.isReceiveTimeout) {
        return "Receive timeout";
      } else if (webApiResult.isError) {
        return webApiResult.message;
      } else {
        return "Unknown error";
      }
    }
  }

  /// Init the data structure
  Future<String?> initFromLocal() async { return null; }

  /// Clear the data structure which holds all <T> instances.
  void clearData();
}

/// A Manager class that stores 1 type
/// The data structure is unknown in this class and it is implemented by mixin:
/// SingleTypeManagerBootstrapMapMixin, data structure = Map<String, T>
/// SingleTypeManagerBootstrapListMixin, data structure = List<T>
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
  String? initWithWebApiResult(WebApiResult webApiResult) {
    final result = super.initWithWebApiResult(webApiResult);
    if (result == null) {
      // Populate dataMap with webApiResult
      final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
      for (final map in list) {
        dataMap[map[uniqueField] ?? ""] = getFromMap(map);
      }
    }
    return result;
  }
}

mixin SingleTypeManagerBootstrapListMixin<T> on SingleTypeManagerBootstrap<T> {

  /// T get(String name) is not implemented. Calling so may cause Exception

  final List<T> dataList = [];
  @override void clearData() => dataList.clear();

  /// Default implementation
  @override
  String? initWithWebApiResult(WebApiResult webApiResult) {
    final result = super.initWithWebApiResult(webApiResult);
    if (result == null) {
      // Populate dataList with
      final list = webApiResult.asListStringMap(fieldName: sourceFieldName);
      dataList.addAll(list.map(getFromMap));
    }
    return result;
  }
}