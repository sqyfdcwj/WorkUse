
import 'Export.dart';

class DataSourceManager extends BootstrapImpl {

  DataSourceManager._();
  static final _instance = DataSourceManager._();
  factory DataSourceManager() => _instance;

  final List<Map<String, String>> _companyList = [];
  List<Map<String, String>> get companyList => _companyList;

  @override
  Future<void> init() async {
    if (isInit) {
      return;
    }
    log("DataSourceManager::init");
    final webApiResult = await webApi.postSingle(
      sqlGroupName: SqlGroupName.getDataSource,
      param: {}
    );
    if (webApiResult.isSuccess) {
      final list = webApiResult.asListStringMap(fieldName: "company_datasource");
      _companyList.addAll(list);
      if (_companyList.isNotEmpty) {
        Global().curCompany.value = _companyList.first;
      }
      isInit = true;
    }
  }
}