
part of growable_controller;

/// The term GC is the abbr of GrowableController

/// A set of callbacks used by the GrowableController
class GCDelegate {

  /// Used by class [GrowableController] and its derived class

  // final SqlGroupName sqlGroupName;
  // final String sqlDisplayName;
  // final String uniqueName;

  final UniqueIdProvider? uniqueIdProvider;

  // final WebApiRequest webApiRequest;

  /// A function that most likely to pop a UI for user to confirm
  final GCParamPredicateFuture? onConfigureParam;

  /// Triggered when *ONE* of following is satisfied:
  /// 1. dataSource is empty, and no dataSource can be obtained from WebApiResult
  /// 2. dataSource is not empty, and becomes empty after called _delete
  ///
  /// By default, calling clear() will not trigger this callback.
  final Future<bool> Function() onEmptyDataSource;

  /// Triggered when a WebApiResult failed.
  /// This method returns a boolean so the method who called this method can
  /// decide whether to exit.
  final WebApiResultPredicateFuture onFail;

  /// Triggered when notifyListener() is called
  final VoidCallback? onNotifyListener;

  /// Triggered when value of currentState changed
  final VoidCallback? onCurrentStateChanged;

  /// Triggered when value of current changed
  final VoidCallback? onCurrentChanged;

  GCDelegate({
    // required this.sqlDisplayName,
    // required this.uniqueName,
    // required this.webApiRequest,
    // this.sqlGroupName = SqlGroupName.stub,
    Future<bool> Function()? onEmptyDataSource,
    WebApiResultPredicateFuture? onFail,
    this.uniqueIdProvider,
    this.onNotifyListener,
    this.onCurrentChanged,
    this.onCurrentStateChanged,
    this.onConfigureParam,
  }): onEmptyDataSource = onEmptyDataSource ?? dlg.handleDataSourceEmpty,
        onFail = onFail ?? dlg.handleWebApiResultOnFail;


  // Future<WebApiResult> webApiRequest(GCParam gcp) async {
  //   return webApi.postSingle(
  //     sqlGroupName: sqlGroupName,
  //     param: gcp.snap
  //   );
  // }
}

enum GCState {

  /// The [GrowableController] will enter this state before it calls
  /// [GrowableControllerDelegate::webApiRequest] to perform network request
  /// The listener can do some UI work here (e.g. display a loading progress bar)
  downloading,

  /// This is a transient state
  /// The [GrowableController] will enter this state when it has just finished the network request
  /// The listener can do some UI work here (e.g dismiss the loading progress bar)
  /// After that, the state will be switched to [GCState.success]
  /// or [GCState.fail] depending on the WebApiResult
  finished,

  /// This state indicates that the last WebApiRequest is successful
  /// The listener can do some UI work here (e.g. refresh the UI)
  success,

  /// This state indicates that the last WebApiRequest failed
  /// The listener can do some UI work here (e.g. refresh the UI)
  fail,
}

class GCItem<T> {

  final GlobalKey key = GlobalKey();
  final T content;
  BuildContext? get context => key.currentContext;
  GCItem(this.content);
}

class GCItemLocation {
  final String key;
  final int idx;
  final bool isValid;
  GCItemLocation._(this.key, this.idx, this.isValid);
  factory GCItemLocation.mapList(String key, int idx) => GCItemLocation._(key, idx, idx > -1);
  factory GCItemLocation.list(int idx) => GCItemLocation._("", idx, idx > -1);
  factory GCItemLocation.invalid() => GCItemLocation._("", -1, false);
}