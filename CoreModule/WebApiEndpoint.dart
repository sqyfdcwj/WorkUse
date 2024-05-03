
import 'TypeDef.dart';

enum SqlGroupName {

  // Services
  getAppConfig,
  getCaption,
  getDatasetFieldLayout,
  getDataSource,
  getDynamicWidget,
  getTextStyle,
  getTextStylePredicate,

  // SqlGroupName for business logic
  getLoginResult,
  getUncheckedPOList,
  getUnconfirmedPOList,
  getPOHistoryList,
  getPODtl,
  getPOVQHistory,
  addPODtlComment,
  checkPO,
  uncheckPO,
  confirmPO,

  getSOList,
  getSODtl,
  addSODtlComment,

  stub,
  ;

  String get capitalizedName => name[0].toUpperCase() + name.substring(1);
}

class WebApiEndpoint {

  final String endpoint;
  final String appVersion;
  final StringMap defaultParameters;

  WebApiEndpoint(this.endpoint, this.appVersion, this.defaultParameters);

  /// This version is for test use and will not insert any log into [apps.sys_api_sql_log]
  static const String appVersionTest = "99999999";

  static WebApiEndpoint get current => test;

  // 10.50.50.226 erp_kayue_trading__20231228
  static final WebApiEndpoint test = WebApiEndpoint(
    "http://intwebapi.kayue-elec.com/20240304/SqlInterfaceMulti.php",
    "20240304",
    { "key": "df80f6cf96a0a585b3e4e35eee749ea5" }
  );

  static final WebApiEndpoint prod = WebApiEndpoint(
    "http://webapi.kayue.com.hk:39801/99999999/SqlInterfaceMulti.php",
    "99999999",

    // 10.50.50.226 erp_kayue_trading__20230608
    { "key": "80bc515f59fda4bc3cf2b75fc5c17c4a" }
  );
}