
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Export.dart';

class LocalStorage extends BootstrapImpl {

  LocalStorage._();
  factory LocalStorage() => _instance;
  static final _instance = LocalStorage._();

  late final PackageInfo _packageInfo;

  String get packageName => _packageInfo.packageName;
  String get version => _packageInfo.version;

  @override
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    log("init, Package name = $packageName");
    isInit = true;
  }

  Future<void> reset() async {
    final pf = await SharedPreferences.getInstance();
    pf.clear();
  }

  void save({ required Map<String, String> map }) async {
    final pf = await SharedPreferences.getInstance();
    for (final entry in map.entries) {
      pf.setString(packageName + entry.key, entry.value);
    }
  }

  Future<Map<String, String>> read() async {
    final pf = await SharedPreferences.getInstance();
    final keySet = pf.getKeys();
    final entries = keySet.map((key) => MapEntry(key.substring(packageName.length), pf.getString(key) ?? ""));
    return Map<String, String>.fromEntries(entries);
  }
}