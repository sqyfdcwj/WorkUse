
import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
BuildContext get rootNavigatorContext => rootNavigatorKey.currentContext!;
NavigatorState get rootNavigatorState => rootNavigatorKey.currentState!;

final TargetPlatform currentPlatform = Theme.of(rootNavigatorContext).platform;

final rootScaffoldKey = GlobalKey<ScaffoldState>();
BuildContext get rootScaffoldContext => rootScaffoldKey.currentContext!;
ScaffoldState get rootScaffoldState => rootScaffoldKey.currentState!;