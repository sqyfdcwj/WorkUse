
part of bootstrap;

/// abstract Bootstrap implementor
abstract class BootstrapImpl {

  /// Return null on success, or detail error message on failure
  Future<String?> init() async {
    print("${runtimeType.toString()}::init");
    return null;
  }
}