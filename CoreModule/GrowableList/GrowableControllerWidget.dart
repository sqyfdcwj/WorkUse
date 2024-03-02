
import 'dart:developer';
import 'package:flutter/material.dart';
import 'GrowableController.dart';

class GrowableControllerRefreshButton extends StatelessWidget {

  final GrowableController controller;
  const GrowableControllerRefreshButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search_rounded, color: Colors.black),
      onPressed: controller.configureParam,
    );
  }
}

class GrowableControllerConfigCriteriaButton extends StatelessWidget {

  final GrowableController controller;
  const GrowableControllerConfigCriteriaButton({ super.key, required this.controller });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.black),
      onPressed: controller.onReachMin,
    );
  }
}
