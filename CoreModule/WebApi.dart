
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'Export.dart';

final webApi = WebApi();

class WebApi {

  WebApi._() {
    setRequestAdditionalInfo("app_version", WebApiEndpoint.appVersion);
  }
  static final WebApi _instance = WebApi._();
  factory WebApi() => _instance;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
  ));

  /// An additional body which will be appended to every single row in every entry in WebApi::postMulti.
  /// Example: Consider a WebApi request to get a list of PO record,
  /// Before adding additional body
  /// {
  ///   "GetUncheckedPOList": [
  ///     {
  ///       "row_id":"0",
  ///       "purchase_no":"",
  ///       "job_no":"",
  ///       "purchase_date_from":"",
  ///       "purchase_date_to":""
  ///     }
  ///   ]
  /// }
  ///
  /// After adding this additional body, the param becomes:
  /// {
  ///   "GetUncheckedPOList": [
  ///     {
  ///       "row_id":"0",
  ///       "purchase_no":"",
  ///       "job_no":"",
  ///       "purchase_date_from":"",
  ///       "purchase_date_to":"",
  ///       "request_user_id":"1",
  ///       "request_username":"ADMIN",
  ///       "request_user_lv":"99",
  ///       "request_staff_id":"0",
  ///       "request_company_id":"1",
  ///       "request_app_version":"99999999"
  ///     }
  ///   ]
  /// }

  /// Every key starts with prefix "request_"
  final Map<String, String> _requestAdditionalInfo = {};
  void setRequestAdditionalInfo(String key, String value) {
    _requestAdditionalInfo["request_$key"] = value;
  }
  void unsetRequestAdditionalInfo(String key) {
    _requestAdditionalInfo.remove("request_$key");
  }

  static WebApiResult _dioErrorHandler(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return WebApiResult.connectTimeout(e.message ?? "");
      case DioExceptionType.receiveTimeout:
        return WebApiResult.receiveTimeout(e.message ?? "");
      case DioExceptionType.connectionError:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return WebApiResult.error(e.message ?? "");
    }
  }

  Future<WebApiResult> postSingle({
    required SqlGroupName sqlGroupName,
    Map<String, dynamic> param = const <String, dynamic>{},
  }) async {
    return postMulti(
      endpoint: WebApiEndpoint.sqlInterface,
      param: { sqlGroupName: [ param ] }
    );
  }

  Future<WebApiResult> postMulti({
    required String endpoint,
    Map<SqlGroupName, List< Map<String, dynamic> > > param = const {},
  }) async {

    try {
      final Response<String> response = await _dio.post(
        endpoint,
        queryParameters: WebApiEndpoint.defaultQueryParameters,
        data: {
          "request": Map<String, List< Map<String, dynamic> > >.fromEntries(
            param.entries.map((entry) {
              return MapEntry(
                entry.key.capitalizedName,
                entry.value.map((map) => Map<String, dynamic>.from(map)..addAll(_requestAdditionalInfo)).toList()
              );
            })
          )
        },
      );
      final json = response.data ?? "";
      return WebApiResult.fromJson(json);
    } on DioException catch (e) {
      log("WebApi::postMulti Error: ${e.type.toString()}, Message = ${e.message}");
      return _dioErrorHandler(e);
    } on SocketException catch (e) {
      log("WebApi::postMulti SocketException, code = ${e.osError?.errorCode ?? 408}");
      return WebApiResult(code: e.osError?.errorCode ?? 408, message: e.osError?.message ?? e.message);
    }
  }
}

class WebApiResult {

  int code;
  bool get isSuccess => code == 0 || code == 200;
  bool get isConnectTimeout => code == 408;
  bool get isReceiveTimeout => code == 504;
  bool get isTimeout => isConnectTimeout || isReceiveTimeout;
  bool get isError => code == 500;

  /// Stores the error message if any. Empty on success result
  String message;

  /// The main body
  Map<String, dynamic> body;

  WebApiResult({
    required this.code,
    required this.message,
    this.body = const {},
  });

  /// Developer is responsible to ensure the returning json from web api can be decoded
  factory WebApiResult.fromJson(String json) {
    try {
      Map<String, dynamic> map = jsonDecode(json);
      return WebApiResult(
        code: map["code"] ?? 500,
        message: map["message"] ?? "Field message is missing",
        body: map["body"] is Map ? map["body"] : {},
      );
    } on FormatException catch (e) {
      log("WebApiResult.fromJson FormatException");
      return WebApiResult.error(e.message);
    } on Exception catch (e) {
      log("WebApiResult.fromJson Exception");
      return WebApiResult.error(e.toString());
    }
  }

  factory WebApiResult.connectTimeout(String message) => WebApiResult(code: 408, message: message);
  factory WebApiResult.receiveTimeout(String message) => WebApiResult(code: 504, message: message);
  factory WebApiResult.error(String message) => WebApiResult(code: 500, message: message);

  Map<String, List<T>> asMapList<T>({
    required String fieldName,
    required T Function(dynamic) toElement,
  }) {
    final raw = body[fieldName];
    return (raw == null) || (raw is! Map<String, List>)
      ? Map<String, List<T>>.identity()
      : raw.map((key, list) => MapEntry(key, list.map(toElement).toList()));
  }

  List<T> asList<T>({
    required String fieldName,
    required T Function(dynamic) toElement,
  }) {
    final raw = body[fieldName];
    return (raw == null) || (raw is! List)
      ? List<T>.empty()
      : raw.map(toElement).toList();
  }

  T asType<T>({
    required String fieldName,
    required T Function(dynamic) toElement,
  }) {
    return toElement(body[fieldName]);
  }

  Map<String, List< Map<String, String> > > asMapListStringMap({ required String fieldName }) {
    return asMapList(fieldName: fieldName, toElement: (e) => Map<String, String>.from(e));
    // try {
    //   Map<String, List> tmpMap = Map<String, List>.from(body[fieldName]);
    //   return tmpMap.map((k, v) => MapEntry(k, v.map((e) => Map<String, String>.from(e)).toList()));
    // } catch (_) {
    //   return {};
    // }
  }

  List< Map<String, String> > asListStringMap({ required String fieldName }) {
    return asList(fieldName: fieldName, toElement: (e) => Map<String, String>.from(e));
    // try {
    //   return List.from(body[fieldName]).map((e) => Map<String, String>.from(e)).toList();
    // } catch (_) {
    //   return [];
    // }
  }

  Map<String, String> listSingle({ required String fieldName }) {
    final list = asListStringMap(fieldName: fieldName);
    return list.isEmpty ? {} : list.first;
  }

  List<String> getKeyList({ required String fieldName }) {
    try {
      return List<String>.from(body["${fieldName}_keys"]);
    } catch (_) {
      return [];
    }
  }

  Map<String, List< Map<String, String> > > allListStringMap() {
    final arrEntry = body.entries;
    final result = <String, List< Map<String, String> > >{};
    for (final entry in arrEntry) { // MapEntry<String, dynamic>
      try {
        List list1 = List.from(entry.value);
        List< Map<String, String> > list2 = list1.map((e) => Map<String, String>.from(e)).toList();
        result[entry.key] = list2;
      } catch (_) {
        continue;
      }
    }
    return result;
  }
}