
part of dialog;

// class DioForNative with DioMixin implements Dio {
//abstract class DioMixin implements Dio {

class DialogUtilIOS implements Dlg {

  OverlayEntry? overlayEntry;

  @override
  Future<bool?> showYesNo({
    String unYes = "",
    String unNo = "",
  }) async {
    global.disableOpenDrawer();
    return showCupertinoDialog(
      barrierDismissible: true,
      context: rootNavigatorContext,
      builder: (context) {
        Widget dialog = CupertinoAlertDialog(
          content: Container(
            color: Colors.green,
          ),
          actions: [
            CupertinoDialogAction(
              child: CaptionField(
                uniqueName: "",
                defaultTextStyle: tsMgr.get("") ?? const TextStyle(fontSize: 16, color: Colors.blue),
                defaultValue: "YES",
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
            CupertinoDialogAction(
              child: CaptionField(
                uniqueName: "",
                defaultTextStyle: tsMgr.get("") ?? const TextStyle(fontSize: 16, color: Colors.red),
                defaultValue: "NO",
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ]
        );
        return WillPopScope(
          onWillPop: () async {
            print("Out of region is tapped");
            global.enableOpenDrawer();
            return true;
          },
          child: dialog
        );
      }
    );

    // return showDialog(context: rootNavigatorContext, builder: (context) {
    //   return CupertinoAlertDialog(
    //     title: Column(children: [
    //       if (isShowDialogIcon)
    //         Icon(titleIcon ?? mapDlgIcon[dlgType], color: Colors.white, size: iconSize ?? _defaultIconSize),
    //       if (title != null)
    //         Text(title, style: styTitle ?? titleTextStyle),
    //       const SizedBox(height: 5),
    //     ]),
    //     content: Column(children: content),
    //     actions: [
    //       if (dlgType != DlgType.confirm)
    //         ..._btnPanelIos(context, returnText: returnText)
    //       else
    //         ..._btnPanelIos2(context, confirmText: confirmText, cancelText: cancelText),
    //     ]
    //   );
    // });
  }


}