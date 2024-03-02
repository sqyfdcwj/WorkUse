
/// The content of this file changes
/// When migrating project, you should not copy this file

import 'Export.dart';

/// ALL variables declared here will be initialized once ONLY when the app is launched

// App Config data
// [
late final expansionTileMaintainState = acMgr.getBool("ExpansionTile_maintainState.default");
late final expansionTileInitiallyExpanded = acMgr.getBool("ExpansionTile_initiallyExpanded.default");

late final scrollableEnsureVisibleDurationMS = acMgr.getInt("Scrollable.ensureVisible.duration.ms") ?? 100;
late final commentBarFutureDelayDurationMS = acMgr.getInt("CommentBar.FutureDelayed.duration.ms") ?? 50;

late final poSearchCriteriaDialogBorderRadius = acMgr.getDouble("POSearchCriteriaDialog.borderRadius");
late final povqHistoryDialogBarrierDismissible = acMgr.getBool("POVQHistoryDialog.barrierDismissible");
late final poSearchCriteriaDialogBarrierDismissible = acMgr.getBool("POSearchCriteriaDialog.barrierDismissible");

// Begin of color data  [apps.flutter_text_style]
// Cell focus color
late final defaultFocusedColor = tsMgr.getColor("Cell.focused");
late final defaultUnfocusedColor = tsMgr.getColor("Cell.unfocused");
late final poListCellFocusedColor = tsMgr.getColor("POListCell.focused");
late final poListCellUnFocusedColor = tsMgr.getColor("POListCell.unfocused");
late final poDtlCellFocusedColor = tsMgr.getColor("PODtlCell.focused");
late final poDtlCellUnfocusedColor = tsMgr.getColor("PODtlCell.unfocused");

// Card data
late final cardThemeColorRoot = tsMgr.getColor("CardTheme.color.root");
late final cardThemeShadowColorRoot = tsMgr.getColor("CardTheme.shadowColor.root");
late final scaffoldBgColorRoot = tsMgr.getColor("Scaffold.backgroundColor.root");

// AppBar data
late final appBarThemeBgColorRoot = tsMgr.getColor("AppBarThemeData.backgroundColor.root");
late final appBarThemeShadowColorRoot = tsMgr.getColor("AppBarThemeData.shadowColor.root");
late final appBarMenuDrawerBgColor = tsMgr.getColor("AppBar.backgroundColor.MenuDrawer");
late final poListAppBarBgColor = tsMgr.getColor("AppBar.backgroundColor.POList");

// Drawer data
late final drawerThemeBgColorRoot = tsMgr.getColor("DrawerTheme.backgroundColor.root");
late final drawerThemeScrimColorRoot = tsMgr.getColor("DrawerTheme.scrimColor.root");

late final statusBarColor = tsMgr.getColor("UIScreen.statusBarColor");
// End of color variable

// Begin of text style data [apps.flutter_text_style]
late final styPOWorkflowHistRejected = tsMgr.get("POWorkflowHistory.rejected");
late final styPOWorkflowHistChecked = tsMgr.get("POWorkflowHistory.checked");
late final styPOWorkflowHistDefault = tsMgr.get("POWorkflowHistory.default");
late final styButtonLabelDefault = tsMgr.get("button.label.default");

late final styMenu = tsMgr.get("menu");
late final styDefault = tsMgr.get("default");
late final styModuleFocused = tsMgr.get("Module.focused");
late final styModuleUnfocused = tsMgr.get("Module.unfocused");
late final styCommentListTile = tsMgr.get("PODtlCommentList.tile");

late final styTitle = tsMgr.get("title");
late final styPOSearchCriteriaCaption = tsMgr.get("POSearchCriteria.caption");
late final styPOSearchCriteriaTitleBlue = tsMgr.get("POSearchCriteria.title.blue");
late final styPOSearchCriteriaTitleRed = tsMgr.get("POSearchCriteria.title.red");
late final styPOSearchCriteriaDefault = tsMgr.get("POSearchCriteria.default");

late final styModuleCaption = tsMgr.get("Module.caption");
late final styStickyListHeader = tsMgr.get("POStickyList.header");

late final styLoginDefault = tsMgr.get("Login.default");
