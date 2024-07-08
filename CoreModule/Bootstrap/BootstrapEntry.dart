
part of bootstrap;

/// Boostrap entry which holds state
class BootstrapEntry {

  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  DateTime? _endTime;
  DateTime? get endTime => _endTime;

  String? _errMsg;
  String? get errMsg => _errMsg;

  int _execTime = 0;
  int get execTime => _execTime;

  bool _isInit = false;
  bool get isInit => _isInit;

  bool get isSuccess => (execTime > 0 && errMsg == null) || execTime == 0;

  /// The real implementor
  BootstrapImpl impl;

  BootstrapEntry(this.impl);

  void _reset() => _isInit = false;

  Future<String?> init({ bool isReset = false }) async {
    if (!isReset && isInit) { return null; }
    if (isReset) { _reset(); }

    _startTime = DateTime.now();
    _errMsg = await impl.init();
    _endTime = DateTime.now();

    _execTime++;
    if (_errMsg == null) {
      _isInit = true;
    }
    return _errMsg;
  }
}