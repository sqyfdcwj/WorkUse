
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'Export.dart';

final captMgr = CaptionManager();

enum CaptionLanguage with EnumUniqueNameMixin {

  en("English"),
  zh_cn("简体中文"),
  zh_tw("繁體中文"),

  ;

  final String displayName;
  const CaptionLanguage(this.displayName);
}

class CaptionManager extends ManagerBootstrapMap<CaptionData> {

  CaptionManager._();
  static final _instance = CaptionManager._();
  factory CaptionManager() => _instance;

  final curLang = ValueNotifier<CaptionLanguage>(CaptionLanguage.en);

  @override final CaptionData defaultValue = CaptionData(
    uniqueName: "",
    en: "",
    zhCN: "",
    zhTW: "",
  );


  @override
  Future<void> init() async {
    clearData();
    await initFromLocal();
    final webApiResult = await webApiRequest;
    isInit = initWithWebApiResult(webApiResult);
  }

  @override
  Future<bool> initFromLocal() async  {
    print("CaptionManager::initFromLocal");
    try {
      final json = await rootBundle.loadString("assets/CaptionManager/caption_data.json");
      final map = jsonDecode(json);
      if (map is Map) {
        for (final entry in map.entries) {
          if (entry.key is! String || entry.value is! Map) {
            continue;
          }
          try {
            dataMap[entry.key] = getFromMap(Map<String, String>.from(entry.value));
          } catch (e) { }
        }
      } else {
        print("The local asset is invalid !");
      }
    } on Exception catch (e) {
      return false;
    }
    return true;
  }

  String? getCaption(String uniqueName, { CaptionLanguage? lang }) {
    return dataMap[uniqueName]?[lang ?? curLang.value];;
  }

  @override
  CaptionData getFromMap(Map<String, String> map) {
    return CaptionData(
      uniqueName: map["unique_name"] ?? "",
      en: map["en"],
      zhCN: map["zh_cn"],
      zhTW: map["zh_tw"],
    );
  }

  @override final String sourceFieldName = "caption_list";
  @override final String uniqueField = "unique_name";
  @override get webApiRequest {
    return webApi.postSingle(
      sqlGroupName: SqlGroupName.getCaption,
      param: {
        "sql_group_version": WebApiEndpoint.appVersion,
      },
    );
  }
}

class CaptionData {

  static String? _nullIf(String? lhs, String? rhs) => lhs == rhs ? null : lhs;

  final String uniqueName;

  final String? _en;
  final String? _zhCN;
  final String? _zhTW;

  CaptionData({
    required this.uniqueName,
    required String? en,
    required String? zhCN,
    required String? zhTW,
  }): _en = _nullIf(en, ""), _zhCN = _nullIf(zhCN, ""), _zhTW = _nullIf(zhTW, "");

  String? operator[](CaptionLanguage lang) {
    switch (lang) {
      case CaptionLanguage.en:
        return _en;
      case CaptionLanguage.zh_cn:
        return _zhCN;
      case CaptionLanguage.zh_tw:
        return _zhTW;
      default:
        return _en;
    }
  }

  String? get caption => this[captMgr.curLang.value];
}