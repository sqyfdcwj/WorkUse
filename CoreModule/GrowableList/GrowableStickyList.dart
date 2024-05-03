
import '../Export.dart';
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class GrowableStickyList<
  I,
  T extends GrowableMapListController<GCDelegate, I>
> extends StatefulWidget {

  final T controller;

  final Widget Function(String) headerBuilder;
  final Widget Function(GCItem<I>) contentBuilder;

  final bool enableOnReachMin;
  final bool enableOnReachMax;

  final int minThreshold;
  final int maxThreshold;

  GrowableStickyList({
    super.key,
    required this.controller,
    required this.headerBuilder,
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
  GrowableStickyListState<I, T> createState() => GrowableStickyListState<I, T>();
}

class GrowableStickyListState<I, T extends GrowableMapListController<GCDelegate, I>> extends State<GrowableStickyList<I, T>> {

  final _scrollController = ScrollController(keepScrollOffset: true);

  late DynamicWidgetData? loadMoreCfg;

  @override
  void initState() {
    loadMoreCfg = dwMgr.get("");
    widget.controller.addListener(cbSetState);
    super.initState();
  }

  @override
  void dispose() {

    _scrollController.dispose();
    widget.controller.removeListener(cbSetState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            for (int idx = 0; idx < widget.controller.keyCount + 1; idx++)
              buildListSection(idx),
          ])
        )
      )
    );
  }

  Widget buildListSection(int idx) {
    if (idx == widget.controller.keyCount) {
      if (widget.controller.isDownloading) {
        return buildDownloadingWidget();
      } else {
        return buildLoadMoreButton();
      }
    }
    return buildStickyHeader(idx);
  }

  Widget buildStickyHeader(int idx) {
    String key = widget.controller.keyAt(idx);
    return StickyHeader(
      header: widget.headerBuilder(key),
      content: ListView.builder(
        physics: const ScrollPhysics(), // DO NOT remove
        itemCount: widget.controller.listLength(key),
        itemBuilder: (_, idx) => itemBuilder(key, idx),
        shrinkWrap: true,
      )
    );
  }

  Widget buildDownloadingWidget() {
    return Padding(
      padding: loadMoreCfg?.padding ?? const EdgeInsets.symmetric(vertical: 5),
      child: const Center(child: CircularProgressIndicator())
    );
  }

  Widget buildLoadMoreButton() {
    if (widget.controller.canLoadMore.value) {
      return ListTile(
        leading: const Icon(Icons.download),
        trailing: const Icon(Icons.download),
        title: Container(
          padding: loadMoreCfg?.padding,
          alignment: loadMoreCfg?.alignment ?? Alignment.center,
          child: Text(captMgr.getCaption("") ?? "Load more"),
        ),
        onTap: widget.controller.onReachMax
      );
    } else {
      return ListTile(
        title: Container(
          padding: loadMoreCfg?.padding,
          alignment: loadMoreCfg?.alignment ?? Alignment.center,
          child: Text(captMgr.getCaption("") ?? "End of the list"),
        ),
      );
    }
  }

  Widget itemBuilder(String key, int idx) {
    final loc = GCItemLocation.mapList(key, idx);
    final item = widget.controller.getItem(loc);
    if (item == null) {
      return Container();
    } else {
      return GestureDetector(
        key: item.key,
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.controller.current.value = item,
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

  void cbSetState() => setState(() { print("GrowableStickyList::cbSetState $hashCode"); });
}