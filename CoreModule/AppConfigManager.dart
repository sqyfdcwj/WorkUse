
library app_config_manager;

import 'Export.dart';

part 'AppConfigManager_var.dart';

final acMgr = AppConfigManager();

/// Value configs downloaded from database
class AppConfigManager extends SingleTypeManagerBootstrap<AppConfig>
  with SingleTypeManagerBootstrapMapMixin<AppConfig> {

  AppConfigManager._();
  static final _instance = AppConfigManager._();
  factory AppConfigManager() => _instance;

  @override AppConfig defaultValue = AppConfig(null, null, null, null);
  @override String get sourceFieldName => "app_config_list";
  @override String get uniqueField => "variable_name";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getAppConfig);

  int? getInt(String name) => get(name)?._intVal;
  String? getString(String name) => get(name)?._strVal;
  double? getDouble(String name) => get(name)?._doubleVal;
  bool? getBool(String name) => get(name)?._boolVal;

  @override
  AppConfig getFromMap(Map<String, String> map) {
    return AppConfig(
      int.tryParse(map["value"] ?? ""),
      double.tryParse(map["value"] ?? ""),
      map["value"],
      AppConfig.parse(map["value"] ?? "")
    );
  }

  final Map<String, ExpansionTileConfig> _expansionTileConfigMap = {};

  ExpansionTileConfig getExpansionTileConfig(String name) {
    if (!_expansionTileConfigMap.containsKey(name)) {
      _expansionTileConfigMap[name] = ExpansionTileConfig._(name);
    }
    return _expansionTileConfigMap[name]!;
  }
}

class AppConfig {
  final int? _intVal;
  final double? _doubleVal;
  final String? _strVal;
  final bool? _boolVal;
  AppConfig(this._intVal, this._doubleVal, this._strVal, this._boolVal);

  static bool parse(String s) => !(s.isEmpty || s == "0" || "false".startsWith(s.toLowerCase()));
}

class ExpansionTileConfig {

  final bool initiallyExpanded;
  final bool maintainState;

  ExpansionTileConfig._(String name):
    initiallyExpanded = acMgr.getBool("ExpansionTile_initiallyExpanded.$name")
      ?? _expansionTileInitiallyExpanded ?? false,
    maintainState = acMgr.getBool("ExpansionTile_maintainState.$name")
      ?? _expansionTileMaintainState ?? false;

  @override
  String toString() {
    return "$hashCode initiallyExpanded: $initiallyExpanded maintainState: $maintainState";
  }
}