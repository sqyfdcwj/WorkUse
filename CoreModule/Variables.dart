
/// When migrating project, you should not copy this file because every Flutter app
/// has their own configurations

/// ALL variables declared in this file will be initialized ONCE ONLY when the app is launched,
/// in _LoadingPageState::bootstrap, which will init services to download data from remote api
///

import 'Export.dart';



// App Config data

late int webApiRequestPageSize = acMgr.getInt("WebApiRequest.pageSize") ?? 50;

late bool? expansionTileMaintainState = acMgr.getBool("ExpansionTile_maintainState.default");
late bool? expansionTileInitiallyExpanded = acMgr.getBool("ExpansionTile_initiallyExpanded.default");

late int scrollableEnsureVisibleDurationMS = acMgr.getInt("Scrollable.ensureVisible.duration.ms") ?? 100;
late int commentBarFutureDelayDurationMS = acMgr.getInt("CommentBar.FutureDelayed.duration.ms") ?? 50;

late double? poSearchCriteriaDialogBorderRadius = acMgr.getDouble("POSearchCriteriaDialog.borderRadius");
late bool? povqHistoryDialogBarrierDismissible = acMgr.getBool("POVQHistoryDialog.barrierDismissible");
late bool? poSearchCriteriaDialogBarrierDismissible = acMgr.getBool("POSearchCriteriaDialog.barrierDismissible");

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


late final styPODtlUndoPO = tsMgr.get("PODtl.btnUndoPO");
late final styPODtlConfirmPO = tsMgr.get("PODtl.btnConfirmPO");

late final styMenu = tsMgr.get("MenuDrawer.menu.caption"); // fontSize: 14, color: Colors.black

// When you declare a const TextStyle() without providing any param,
// The default value is fontSize: 14, color: Colors.black
late final styDefault = tsMgr.get("default");
late final styModuleFocused = tsMgr.get("Module.focused");
late final styModuleUnfocused = tsMgr.get("Module.unfocused");
late final styCommentListTile = tsMgr.get("PODtlCommentList.tile");

// fontSize: 18, color: Colors.black
late final styTitle = tsMgr.get("title");
late final styPOSearchCriteriaCaption = tsMgr.get("POSearchCriteria.caption");
late final styPOSearchCriteriaBtnSave = tsMgr.get("POSearchCriteria.btnSave");
late final styPOSearchCriteriaBtnCancel = tsMgr.get("POSearchCriteria.btnCancel");
late final styPOSearchCriteriaBtnReset = tsMgr.get("POSearchCriteria.btnReset");
late final styPOSearchCriteriaDefault = tsMgr.get("POSearchCriteria.default");

late final styModuleCaption = tsMgr.get("Module.caption");
late final styStickyListHeader = tsMgr.get("POStickyList.header");

late final styLoginDefault = tsMgr.get("Login.default");
