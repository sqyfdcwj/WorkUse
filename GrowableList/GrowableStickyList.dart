
import '../CoreModule/Export.dart';
import 'package:flutter/material.dart';
import 'GrowableController.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import '../Constants/TypeDef.dart';

class GrowableStickyList<T extends GrowableStickyListController> extends StatefulWidget {

  final T controller;

  final Widget Function(String) headerBuilder;
  final Widget Function(Map<String, String>) contentBuilder;

  final int minThreshold;
  final int maxThreshold;

  final void Function() onReachMin;
  final void Function() onReachMax;

  GrowableStickyList({
    super.key,
    required this.controller,
    required this.headerBuilder,
    required this.contentBuilder,
    this.minThreshold = 150,
    this.maxThreshold = 150,
    required this.onReachMin,
    required this.onReachMax,
  }) {
    assert(minThreshold > 0);
    assert(maxThreshold > 0);
  }

  @override
  GrowableStickyListState createState() => GrowableStickyListState();
}

class GrowableStickyListState extends State<GrowableStickyList> {

  final _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void initState() {
    log("Widget::controller addListener");
    widget.controller.addListener(cbSetState);
    super.initState();
  }

  @override
  void dispose() {
    log("Growable dispose");
    _scrollController.dispose();
    widget.controller.removeListener(cbSetState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log("GrowableStickyListState::build $hashCode");
    if (widget.controller.dataSource.isEmpty) {
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
          itemCount: widget.controller.arrDataSourceKey.length,
          itemBuilder: (_, index) {
            String key = widget.controller.arrDataSourceKey[index];
            return StickyHeader(
              header: widget.headerBuilder(key),
              content: ListView.builder(
                physics: const ScrollPhysics(), // DO NOT remove
                itemCount: widget.controller.dataSource[key]!.length,
                itemBuilder: (_, idx) => widget.contentBuilder(widget.controller.dataSource[key]![idx]),
                shrinkWrap: true,
              )
            );
          }
        )
      )
    );
  }

  void onPointerUp(PointerUpEvent _) {
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent - widget.minThreshold) {
      widget.onReachMin();
    }
    else if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent + widget.maxThreshold) {
      widget.onReachMax();
    }
  }

  void cbSetState() => setState(() { log("GrowableList::cbSetState $hashCode"); });
}