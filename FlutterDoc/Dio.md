https://pub.dev/packages/dio/versions

/// The base config for the Dio instance, used by [Dio.options].
class BaseOptions extends _RequestConfig with OptionsMixin { 
    
    BaseOptions({
        String? method,
        Duration? connectTimeout,
        Duration? receiveTimeout,
        Duration? sendTimeout,
        String baseUrl = '',
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? extra,
        Map<String, dynamic>? headers,
        bool preserveHeaderCase = false,
        ResponseType? responseType = ResponseType.json,
        String? contentType,
        ValidateStatus? validateStatus,
        bool? receiveDataWhenStatusError,
        bool? followRedirects,
        int? maxRedirects,
        bool? persistentConnection,
        RequestEncoder? requestEncoder,
        ResponseDecoder? responseDecoder,
        ListFormat? listFormat,
    }) 
}

In DioMixin::request:


// RequestOptions Options::compose
final requestOptions = (options ?? Options()).compose(
    this.options,   // The BaseOption
    path,
    data: data,
    queryParameters: queryParameters,
    onReceiveProgress: onReceiveProgress,
    onSendProgress: onSendProgress,
    cancelToken: cancelToken,
    sourceStackTrace: StackTrace.current,
);

final requestOptions = RequestOptions(
    method: method,
    headers: headers,
    extra: extra,
    baseUrl: baseOpt.baseUrl,
    path: path,
    data: data,
    preserveHeaderCase: preserveHeaderCase ?? baseOpt.preserveHeaderCase,
    sourceStackTrace: sourceStackTrace ?? StackTrace.current,
    
    connectTimeout: baseOpt.connectTimeout,
    
    sendTimeout: sendTimeout ?? baseOpt.sendTimeout,
    receiveTimeout: receiveTimeout ?? baseOpt.receiveTimeout,
    responseType: responseType ?? baseOpt.responseType,
    validateStatus: validateStatus ?? baseOpt.validateStatus,
    receiveDataWhenStatusError:
        receiveDataWhenStatusError ?? baseOpt.receiveDataWhenStatusError,
    followRedirects: followRedirects ?? baseOpt.followRedirects,
    maxRedirects: maxRedirects ?? baseOpt.maxRedirects,
    persistentConnection:
        persistentConnection ?? baseOpt.persistentConnection,
    queryParameters: query,
    requestEncoder: requestEncoder ?? baseOpt.requestEncoder,
    responseDecoder: responseDecoder ?? baseOpt.responseDecoder,
    listFormat: listFormat ?? baseOpt.listFormat,
    onReceiveProgress: onReceiveProgress,
    onSendProgress: onSendProgress,
    cancelToken: cancelToken,
    contentType: contentType ?? this.contentType ?? baseOpt.contentType,
);

We can see that, the connectTimeout can be set only ONCE 