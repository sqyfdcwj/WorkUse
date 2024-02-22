
import '../Constants/TypeDef.dart';
import 'Export.dart';

class DataSourceManager extends BootstrapImpl {

  DataSourceManager._();
  static final _instance = DataSourceManager._();
  factory DataSourceManager() => _instance;

  final Set<String> _companyIdSet = {};
  final ListStringMap _companyList = [];
  ListStringMap get companyList => _companyList;

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
      print("Init Company dataSource");
      final list = webApiResult.asListStringMap(fieldName: "company_datasource");
      _companyList.addAll(list);
      _companyList.retainWhere((map) => _companyIdSet.add(map["company_id"] ?? ""));
      if (_companyList.isNotEmpty) {
        Global().curCompany.value = _companyList.first;
      }
      isInit = true;
    }
  }
}