
import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
BuildContext get rootNavigatorContext => rootNavigatorKey.currentContext!;
NavigatorState get rootNavigatorState => rootNavigatorKey.currentState!;

final TargetPlatform currentPlatform = Theme.of(rootNavigatorContext).platform;
late final bool isAndroid = currentPlatform == TargetPlatform.android;
late final bool isIOS = currentPlatform == TargetPlatform.iOS;

final rootScaffoldKey = GlobalKey<ScaffoldState>();
BuildContext get rootScaffoldContext => rootScaffoldKey.currentContext!;
ScaffoldState get rootScaffoldState => rootScaffoldKey.currentState!;