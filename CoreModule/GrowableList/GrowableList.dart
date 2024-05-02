
import '../Export.dart';
import 'package:flutter/material.dart';

class GrowableList<
  I,
  T extends GrowableListController<GCDelegate, I>
> extends StatefulWidget {

  final T controller;
  final Widget Function(GCItem<I>) contentBuilder;

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
  GrowableListState<I, T> createState() => GrowableListState<I, T>();
}

class GrowableListState<I, T extends GrowableListController<GCDelegate, I>> extends State<GrowableList<I, T>> {

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // DO NOT remove
          controller: _scrollController,
          child: Column(children: [
            for (int idx = 0; idx < widget.controller.elementCount; idx++)
              buildListSection(idx),
          ]),
        )
      )
    );
  }

  Widget buildListSection(int idx) {
    final loc = GCItemLocation.list(idx);
    final item = widget.controller.getItem(loc);
    if (item == null) {
      return Container();
    } else {
      return GestureDetector(
        key: item.key,
        onTap: () {
          widget.controller.current.value = item;
        },
        child: widget.contentBuilder(item)
      );
    }
  }

  // End of ui

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