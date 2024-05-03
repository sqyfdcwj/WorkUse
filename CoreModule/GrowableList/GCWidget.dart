
import 'package:flutter/material.dart';
import 'GCInclude.dart';

enum GCAction {

  refresh(Icons.refresh),
  openCriteria(Icons.search),
  locateFirst(Icons.first_page),
  locateCurrent(Icons.location_searching),
  locateLast(Icons.last_page),
  ;

  final IconData iconData;
  const GCAction(this.iconData);
}

class GCOpenCriteriaButton extends StatelessWidget {

  final GrowableController controller;
  const GCOpenCriteriaButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.requestParam,
      builder: (context, _) {
        return IconButton(
          icon: Icon(Icons.search_rounded,
            color: controller.requestParam.modified
              ? Colors.blue
              : Colors.black
          ),
          onPressed: controller.configureParam,
        );
      },
    );
  }
}

class GCRefreshButton extends StatelessWidget {

  final GrowableController controller;
  const GCRefreshButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.black),
      onPressed: controller.onReachMin,
    );
  }
}

class GCGotoFirstButton extends StatelessWidget {

  final GrowableController controller;
  const GCGotoFirstButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.first_page, color: Colors.black),
      onPressed: () {
        final itemContext = controller.firstItem?.context;
        if (itemContext == null) { return; }
        Scrollable.ensureVisible(
          itemContext,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
    );
  }
}

class GCGotoCurrentButton extends StatelessWidget {

  final GrowableController controller;
  const GCGotoCurrentButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.fmd_good, color: Colors.black),
      onPressed: () {
        final itemContext = controller.currentItem?.context;
        if (itemContext == null) { return; }
        Scrollable.ensureVisible(
          itemContext,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
    );
  }
}

class GCGotoLastButton extends StatelessWidget {

  final GrowableController controller;
  const GCGotoLastButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.last_page, color: Colors.black),
      onPressed: () {
        final itemContext = controller.lastItem?.context;
        if (itemContext == null) { return; }
        Scrollable.ensureVisible(
          itemContext,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
    );
  }
}