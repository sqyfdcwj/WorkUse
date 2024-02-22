
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'Export.dart';

final webApi = WebApi();

class WebApi {

  WebApi._();
  static final WebApi _instance = WebApi._();
  factory WebApi() => _instance;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
  ));

  Map<String, String> get webApiRequest {
    return {
      "request_user_id": global.userId,
      "request_username": global.username,
      "request_user_lv": global.userLv,
      "request_staff_id": global.staffId,
      "request_company_id": global.curCompanyId,
      "request_app_version": WebApiEndpoint.appVersion,
    };
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
    required Map<String, dynamic> param,
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
    log("WebApi::postMulti, endpoint = $endpoint");
    try {
      final Response<String> response = await _dio.post(
        endpoint,
        queryParameters: WebApiEndpoint.defaultQueryParameters,
        data: {
          "request": Map<String, List< Map<String, dynamic> > >.fromEntries(
            param.entries.map((entry) {
              return MapEntry(
                entry.key.capitalizedName,
                entry.value.map((map) => map..addAll(webApiRequest)).toList()
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

  /// Input dynamic type raw and try cast to a typed map. Return empty map on fail or raw is empty
  Map<String, List<T>> getMap<T>({
    required dynamic raw,
    required T Function(dynamic) toElement
  }) {
    if ((raw == null) || (raw is! Map<String, dynamic>)) {
      log("WebApiResult::getMap guard");
      return {};
    }
    return raw.map((key, list) => MapEntry(key, (list as List).map(toElement).toList()));
  }

  /// Input dynamic type raw and try cast to a typed array. Return empty array on fail or raw is empty
  List<T> getList<T>({
    required dynamic raw,
    required T Function(dynamic) toElement,
  }) {
    if ((raw == null) || (raw is! List)) {
      log("WebApiResult::getList guard");
      return [];
    }
    return raw.map(toElement).toList();
  }

  T? getField<T>({
    required String fieldName,
    T? Function(dynamic)? toElement,
  }) {
    toElement ??= defaultToElement;
    return toElement(body[fieldName]);
  }

  T? defaultToElement<T>(dynamic raw) => raw as T;

  Map<String, List<T>> asMapList<T>({
    required String fieldName,
    required T Function(dynamic) toElement
  }) => getMap(raw: body[fieldName], toElement: toElement);

  List<T> asList<T>({
    required String fieldName,
    required T Function(dynamic) toElement
  }) => getList(raw: body[fieldName], toElement: toElement);

  Map<String, List< Map<String, String> > > asMapListStringMap({ required String fieldName }) {
    try {
      Map<String, List> tmpMap = Map<String, List>.from(body[fieldName]);
      return tmpMap.map((k, v) => MapEntry(k, v.map((e) => Map<String, String>.from(e)).toList()));
    } catch (_) {
      return {};
    }
  }

  List< Map<String, String> > asListStringMap({ required String fieldName }) {
    try {
      return List.from(body[fieldName]).map((e) => Map<String, String>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, String> single({ required String fieldName }) {
    final list = asListStringMap(fieldName: fieldName);
    return list.isEmpty ? {} : list.first;
  }

  List<String> getKeyListFromBody({ required String fieldName }) {
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