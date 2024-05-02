
part of growable_controller;

class GCRequest {

  final SqlGroupName sqlGroupName;
  final String sqlDisplayName;
  final String uniqueName;

  final GCParam param;

  const GCRequest({
    required this.sqlGroupName,
    required this.sqlDisplayName,
    required this.uniqueName,
    required this.param,
  });

  Future<WebApiResult> exec() async {
    return webApi.postSingle(sqlGroupName: sqlGroupName, param: param.asStringMap);
  }
}