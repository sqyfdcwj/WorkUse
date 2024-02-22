
library dialog;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Export.dart';

part 'DialogUtil_Android.dart';
part 'DialogUtil_iOS.dart';

enum DlgType { success, fail, alert, confirm, }

final dlg2 = isAndroid ? DialogUtilAndroid() : DialogUtilIOS();
final dlg = DialogUtil();

abstract class Dlg {

  Future<bool?> showYesNo({
    String unYes = "",
    String unNo = "",
  });
}

abstract class DlgMixin implements Dlg {

}


class DialogUtil {

  DialogUtil._();
  static final _instance = DialogUtil._();
  factory DialogUtil() => _instance;

  late final Map<DlgType, Color> mapDlgColor = {
    DlgType.success: Colors.green.shade400,
    DlgType.fail: Colors.red.shade400,
    DlgType.alert: Colors.red.shade400,
    DlgType.confirm: Colors.blue.shade400,
  };

  late final Map<DlgType, IconData> mapDlgIcon = {
    DlgType.success: Icons.check_circle_outline,
    DlgType.fail: Icons.error,
    DlgType.alert: Icons.warning_amber,
    DlgType.confirm: Icons.question_mark,
  };

  TextStyle get titleTextStyle {
    if (currentPlatform == TargetPlatform.iOS) {
      return const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold);
    } else {
      return const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold);
    }
  }

  TextStyle buttonTextStyle = const TextStyle(fontSize: 16, color: Colors.white);

  double _defaultIconSize = 75;
  set iconSize(double value) {
    if (value <= 0) { return; }
    _defaultIconSize = value;
  }

  String get _defaultConfirmText => captMgr.getCaption("lblDialogConfirm") ?? "YES";
  String get _defaultCancelText => captMgr.getCaption("lblDialogCancel") ?? "NO";
  String get _defaultReturnText => captMgr.getCaption("lblDialogReturn") ?? "OK";

  set borderRadius(double value) {
    if (value <= 0) {
      return;
    }
    _radius = Radius.circular(value);
  }

  Radius _radius = const Radius.circular(5);

  Future<bool?> show(DlgType dlgType, {
    Color iconColor = Colors.white,
    IconData? titleIcon,
    String? title,
    TextStyle? styTitle,
    double? iconSize,
    Color? contentColor,
    Color actionColor = Colors.white,
    double? radius,
    bool isShowDialogIcon = false,
    String? confirmText,
    String? cancelText,
    String? returnText,
    List<Widget> content = const [],
    EdgeInsets titlePadding = const EdgeInsets.all(20),
    EdgeInsets contentPadding = const EdgeInsets.all(10),
  }) async {
    if (currentPlatform == TargetPlatform.iOS) {
      return _showIos(dlgType,
        iconColor: iconColor,
        titleIcon: titleIcon,
        title: title,
        styTitle: styTitle,
        iconSize: iconSize,
        contentColor: contentColor,
        actionColor: actionColor,
        radius: radius,
        isShowDialogIcon: isShowDialogIcon,
        confirmText: confirmText,
        cancelText: cancelText,
        returnText: returnText,
        content: content,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
      );
    } else {
      return _showAndroid(dlgType,
        iconColor: iconColor,
        titleIcon: titleIcon,
        title: title,
        styTitle: styTitle,
        iconSize: iconSize,
        contentColor: contentColor,
        actionColor: actionColor,
        radius: radius,
        isShowDialogIcon: isShowDialogIcon,
        confirmText: confirmText,
        cancelText: cancelText,
        returnText: returnText,
        content: content,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
      );
    }
  }

  Future<bool?> _showAndroid(DlgType dlgType, {
    Color iconColor = Colors.white,
    IconData? titleIcon,
    String? title,
    TextStyle? styTitle,
    double? iconSize,
    Color? contentColor,
    Color actionColor = Colors.white,
    double? radius,
    bool isShowDialogIcon = true,
    String? confirmText,
    String? cancelText,
    String? returnText,
    List<Widget> content = const [],
    EdgeInsets titlePadding = const EdgeInsets.all(20),
    EdgeInsets contentPadding = const EdgeInsets.all(10),
  }) async {
    Radius rad = (radius != null && radius > 0) ? Radius.circular(radius) : _radius;
    return showDialog(context: rootNavigatorContext, builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.transparent,
        title: DecoratedBox(
          decoration: BoxDecoration(
            color: contentColor ?? mapDlgColor[dlgType],
            borderRadius: BorderRadius.only(topLeft: rad, topRight: rad)
          ),
          child: Padding(
            padding: titlePadding,
            child: Column(children: [
              if (isShowDialogIcon)
                Icon(titleIcon ?? mapDlgIcon[dlgType], color: Colors.white, size: iconSize ?? _defaultIconSize),
              if (title != null)
                Text(title, style: styTitle ?? titleTextStyle),
              const SizedBox(height: 5),
              ...content,
            ])
          )
        ),
        titlePadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(_radius)),
        titleTextStyle: buttonTextStyle,
        content: Container(
          padding: contentPadding,
          decoration: BoxDecoration(
            color: actionColor,
            borderRadius: BorderRadius.only(bottomLeft: rad, bottomRight: rad)
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (dlgType != DlgType.confirm)
              _btnPanel(context, dlgType, returnText: returnText)
            else
              _btnPanel2(context, dlgType, confirmText: confirmText, cancelText: cancelText),
          ])
        ),
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        contentTextStyle: buttonTextStyle,
      );
    });
  }

  Future<bool?> _showIos(DlgType dlgType, {
    Color iconColor = Colors.white,
    IconData? titleIcon,
    String? title,
    TextStyle? styTitle,
    double? iconSize,
    Color? contentColor,
    Color actionColor = Colors.white,
    double? radius,
    bool isShowDialogIcon = true,
    String? confirmText,
    String? cancelText,
    String? returnText,
    List<Widget> content = const [],
    EdgeInsets titlePadding = const EdgeInsets.all(20),
    EdgeInsets contentPadding = const EdgeInsets.all(10),
  }) async {
    return showDialog(context: rootNavigatorContext, builder: (context) {
      return CupertinoAlertDialog(
        title: Column(children: [
          if (isShowDialogIcon)
            Icon(titleIcon ?? mapDlgIcon[dlgType], color: Colors.white, size: iconSize ?? _defaultIconSize),
          if (title != null)
            Text(title, style: styTitle ?? titleTextStyle),
          const SizedBox(height: 5),
        ]),
        content: Column(children: content),
        actions: [
          if (dlgType != DlgType.confirm)
            ..._btnPanelIos(context, returnText: returnText)
          else
            ..._btnPanelIos2(context, confirmText: confirmText, cancelText: cancelText),
        ]
      );
    });
  }

  Row _btnPanel(BuildContext context, DlgType dlgType, { String? returnText }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: mapDlgColor[dlgType],
            elevation: 0,
            textStyle: buttonTextStyle,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(_radius)),
          ),
          child: Text(returnText ?? _defaultReturnText),
        ),
      ]
    );
  }

  Row _btnPanel2(BuildContext context, DlgType dlgType, { String? confirmText, String? cancelText, }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: mapDlgColor[dlgType],
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmText ?? _defaultConfirmText, style: buttonTextStyle),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(cancelText ?? _defaultCancelText, style: buttonTextStyle.copyWith(color: mapDlgColor[dlgType])),
        ),
      ]
    );
  }

  List<Widget> _btnPanelIos(BuildContext context, { String? returnText }) {
    return [
      CupertinoDialogAction(
        child: Text(returnText ?? _defaultReturnText, style: buttonTextStyle.copyWith(color: Colors.blue)),
        onPressed: () => Navigator.pop(context, false),
      ),
    ];
  }

  List<Widget> _btnPanelIos2(BuildContext context, { String? confirmText, String? cancelText }) {
    return [
      CupertinoDialogAction(
        child: Text(confirmText ?? _defaultConfirmText, style: buttonTextStyle.copyWith(color: Colors.blue)),
        onPressed: () => Navigator.pop(context, true),
      ),
      CupertinoDialogAction(
        child: Text(cancelText ?? _defaultCancelText, style: buttonTextStyle.copyWith(color: Colors.red)),
        onPressed: () => Navigator.pop(context, false),
      ),
    ];
  }

  Future<T?> showFullScreenCover<T>({
    required Widget child,
  }) {
    return showDialog<T>(
      context: rootNavigatorContext,
      useSafeArea: false,
      builder: (BuildContext context) {
        return child;
      },
    );
  }

  Future<T?> showGeneral<T>({
    required Widget child,
    bool barrierDismissible = false,
    EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: 75, vertical: 50)
  }) {
    return showGeneralDialog<T>(
      context: rootNavigatorContext,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: barrierDismissible,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: const Offset(0, 0)
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeIn)),
        child: child,
      ),
      pageBuilder: (_, __, ___) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: insetPadding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: child,
      )
    );
  }

  /// If the webApiResult is not success, show dialog and return false
  /// So the method invoked this method could return
  bool dlgWithWebApiResult(WebApiResult webApiResult) {
    if (webApiResult.isConnectTimeout) {
      dlg.show(DlgType.alert, title: captMgr.getCaption("dlgWebApiConnTimeout") ?? "Connection timeout");
      return false;
    } else if (webApiResult.isReceiveTimeout) {
      dlg.show(DlgType.alert, title: captMgr.getCaption("dlgWebApiRecvTimeout") ?? "Receive timeout");
      return false;
    } else if (webApiResult.isError) {
      dlg.show(DlgType.alert, title: captMgr.getCaption("dlgWebApiError") ?? "Error");
      return false;
    }
    return true;
  }
}
