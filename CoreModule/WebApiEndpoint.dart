
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

  // 10.50.50.226 erp_kayue_trading__20230608
  static String get keyKayue => "80bc515f59fda4bc3cf2b75fc5c17c4a";

  // Must be implemented, used by WebApi
  static String get key => keyKayue;

  // Must be implemented, used by CaptionManager
  static String get appVersion => "99999999";  // This version will not log

  // http://intwebapi.kayue-elec.com
  // http://webapi.kayue.com.hk:39801
  static get hostTest => "http://intwebapi.kayue-elec.com";
  static get hostProd => "http://webapi.kayue.com.hk:39801";

  static get host => hostTest;
  static get endpointDir => "$host/$appVersion";

  // Must be implemented, used by WebApi
  static get sqlInterface => "$endpointDir/SqlInterfaceMulti.php";

  // Must be implemented, used by WebApi
  static get defaultQueryParameters => { "key": key };
}