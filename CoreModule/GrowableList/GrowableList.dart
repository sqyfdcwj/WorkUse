
import '../Export.dart';
import 'package:flutter/material.dart';

class GrowableList<T extends GrowableListController> extends StatefulWidget {

  final T controller;

  final Widget Function(int) contentBuilder;

  final bool enableOnReachMin;
  final bool enableOnReachMax;

  final int minThreshold;
  final int maxThreshold;

  GrowableList({
    super.key,
    required this.controller,
    required this.contentBuilder,
    this.enableOnReachMin = true,
    this.enableOnReachMax = true,
    this.minThreshold = 150,
    this.maxThreshold = 150,
  }) {
    assert(minThreshold > 0);
    assert(maxThreshold > 0);
  }

  @override
  GrowableListState createState() => GrowableListState();
}

class GrowableListState extends State<GrowableList> {

  final _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void initState() {
    // log("Widget::controller addListener");
    widget.controller.addListener(cbSetState);
    super.initState();
  }

  @override
  void dispose() {
    // log("Growable dispose");
    _scrollController.dispose();
    widget.controller.removeListener(cbSetState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // log("GrowableStickyListState::build $hashCode");
    if (widget.controller.isEmpty) {
      if (widget.controller.isDownloading) {
        return const Center(child: CaptionField(uniqueName: "lblDownloading", defaultValue: "Downloading"));
      } else {
        return const Center(child: CaptionField(uniqueName: "lblNoRecord", defaultValue: "No record"));
      }
    }

    return Listener(
      onPointerUp: onPointerUp,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) => false,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(), // DO NOT remove
          controller: _scrollController,
          itemCount: widget.controller.elementCount,
          itemBuilder: (_, idx) => widget.contentBuilder(idx),
          shrinkWrap: true,
        )
      )
    );
  }

  void onPointerUp(PointerUpEvent _) {
    if (widget.enableOnReachMin
        && _scrollController.position.pixels <= _scrollController.position.minScrollExtent - widget.minThreshold
    ) {
      widget.controller.onReachMin();
    } else if (widget.enableOnReachMax
        && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent + widget.maxThreshold
    ) {
      widget.controller.onReachMax();
    }
  }

  void cbSetState() => setState(() { print("GrowableList::cbSetState $hashCode"); });
}