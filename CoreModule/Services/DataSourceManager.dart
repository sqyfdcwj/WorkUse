
import '../Export.dart';

final dsMgr = DataSourceManager();

class DataSourceManager extends ManagerBootstrap {

  DataSourceManager._();
  static final _instance = DataSourceManager._();
  factory DataSourceManager() => _instance;

  final UniqueList _companyList = UniqueList("company_id");
  Iterable<StringMap> get companyList => _companyList.list;

  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getDataSource);

  @override
  void clearData() {
    _companyList._clear();
  }

  @override
  String? initWithWebApiResult(WebApiResult webApiResult) {
    final result = super.initWithWebApiResult(webApiResult);
    if (result == null) {
      final list = webApiResult.asListStringMap(fieldName: "company_datasource");
      if (list.isNotEmpty) {
        _companyList._clear();
        _companyList._addAll(list);
        if (!_companyList.isEmpty) {
          global.curCompany.value = _companyList.first;
        }
      }
    }
    return result;
  }

  @override
  Future<String?> initFromLocal() async {
    return _companyList._loadFromAssets("assets/DataSourceManager/company_data.json");
  }
}

class UniqueList {

  String idField;
  final Set<String> _idSet = {};
  final ListStringMap _list = [];
  Iterable<StringMap> get list => _list;

  UniqueList(this.idField);

  bool get isEmpty => _list.isEmpty;

  void _clear() {
    _idSet.clear();
    _list.clear();
  }

  void _add(StringMap map) {
    if (map[idField] != null && _idSet.add(map[idField]!)) {
      _list.add(map);
    }
  }

  void _addAll(Iterable<StringMap> list) => list.forEach(_add);

  StringMap? operator[](String id) {
    final idx = _list.indexWhere((element) => (element[idField] != null && element[idField]! == id));
    return idx != -1 ? _list[idx] : null;
  }

  StringMap? get first => _list.isNotEmpty ? _list.first : null;
  StringMap? get last => _list.isNotEmpty ? _list.last : null;

  Future<String?> _loadFromAssets(String path) async {
    try {
      final json = await rootBundle.loadString(path);
      final list = jsonDecode(json);
      if (list is! List) {
        print("localAsset is invalid. Please fix");
        return "localAsset is invalid. Please fix";
      }
      for (final map in list) {
        if (map is Map) {
          _add(StringMap.from(map));
        } else {
          print("UniqueList::_loadFromAssets element is not StringMap");
        }
      }
      print("UniqueList::_loadFromAssets OK");
      return null;
    } on Exception catch (e) {
      print("UniqueList::_loadFromAssets Exception");
      return "UniqueList::_loadFromAssets Exception";
    }
  }
}