
import '../Export.dart';

final dsMgr = DataSourceManager();

class DataSourceManager extends ManagerBootstrap {

  DataSourceManager._();
  static final _instance = DataSourceManager._();
  factory DataSourceManager() => _instance;

  final Set<String> _companyIdSet = {};
  final List<Map<String, String>> _companyList = [];
  Iterable<Map<String, String>> get companyList => _companyList;

  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getDataSource);

  @override
  void clearData() {
    _companyIdSet.clear();
    _companyList.clear();
  }

  @override
  bool initWithWebApiResult(WebApiResult webApiResult) {
    if (!super.initWithWebApiResult(webApiResult)) { return false; }
    final list = webApiResult.asListStringMap(fieldName: "company_datasource");
    _companyList.addAll(list);
    _companyList.retainWhere((map) => _companyIdSet.add(map["company_id"] ?? ""));
    if (_companyList.isNotEmpty) {
      global.curCompany.value = _companyList.first;
    }
    return true;
  }
}