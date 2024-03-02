
import 'dart:developer';
import 'package:flutter/material.dart';

enum ViewState {
  init,
  downloading,
  success,
  fail,
}

mixin ViewStateMixin<T extends StatefulWidget> on State<T> {

  ViewState _viewState = ViewState.init;
  ViewState get viewState => _viewState;
  set viewState(ViewState value) {
    onViewStateChanged(value);
    if (shouldSetState(viewState, value)) {
      setState(() => _viewState = value);
    } else {
      _viewState = value;
    }
  }

  bool shouldSetState(ViewState oldState, ViewState newState) => true;

  void onViewStateChanged(ViewState newState) {}

  Widget widgetOnInit() => Container();
  Widget widgetOnDownloading() => Container();
  Widget widgetOnSuccess() => Container();
  Widget widgetOnFail() => Container();

  late final Map<ViewState, Widget Function()> _mapWidget = {
    ViewState.init: widgetOnInit,
    ViewState.downloading: widgetOnDownloading,
    ViewState.success: widgetOnSuccess,
    ViewState.fail: widgetOnFail,
  };

  Widget get widgetCurrentState {
    return _mapWidget[viewState]!.call();
  }
}