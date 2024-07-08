
import '../Export.dart';

final captMgr = CaptionManager();

enum CaptionLanguage with EnumUniqueNameMixin {

  en("English"),
  zh_cn("简体中文"),
  zh_tw("繁體中文"),

  ;

  @override
  final String displayName;
  const CaptionLanguage(this.displayName);
}

/// This module is not in use now
class CaptionManager extends SingleTypeManagerBootstrap<CaptionData>
  with SingleTypeManagerBootstrapMapMixin<CaptionData> {

  CaptionManager._();
  static final _instance = CaptionManager._();
  factory CaptionManager() => _instance;

  final curLang = ValueNotifier<CaptionLanguage>(CaptionLanguage.en);

  @override final CaptionData defaultValue = CaptionData(uniqueName: "", en: "", zhCN: "", zhTW: "");
  @override final String sourceFieldName = "caption_list";
  @override final String uniqueField = "unique_name";
  @override get webApiRequest => webApi.postSingle(sqlGroupName: SqlGroupName.getCaption);

  @override
  CaptionData getFromMap(StringMap map) {
    return CaptionData(
      uniqueName: map["unique_name"] ?? "",
      en: map["en"],
      zhCN: map["zh_cn"],
      zhTW: map["zh_tw"],
    );
  }

  @override
  Future<String?> initFromLocal() async  {
    print("CaptionManager::initFromLocal");
    try {
      final json = await rootBundle.loadString("assets/CaptionManager/caption_data.json");
      final list = jsonDecode(json);
      if (list is! List) {
        return "CaptionManager local asset is invalid";
      }
      for (final map in list) {
        if (map is Map) {
          dataMap[map[uniqueField] ?? ""] = getFromMap(StringMap.from(map));
        } else {
          print("CaptionManager::initFromLocal element is not StringMap");
        }
      }
    } on Exception catch (e) {
      return e.toString();
    }
    return null;
  }

  String? getCaption(String uniqueName, { CaptionLanguage? lang }) {
    return dataMap[uniqueName]?[lang ?? curLang.value];;
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