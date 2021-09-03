import 'package:flutter/foundation.dart';

/// @author jd
import 'package:flutter/material.dart';

import 'tracker_inherited_widget.dart';
import 'tracker_state.dart';

class TrackerItemWidget extends StatefulWidget {
  const TrackerItemWidget({
    Key? key,
    required this.id,
    required this.builder,
    this.displayNotifier,
    this.trackerStrategy = TrackerStrategy.only,
    this.child,
  }) : super(key: key);

  final String id;

  final InViewNotifierWidgetBuilder builder;

  final TrackerStrategy trackerStrategy;

  final DisplayNotifier? displayNotifier;

  ///The child widget to pass to the builder.
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _TrackerItemWidgetState();
}

class _TrackerItemWidgetState extends State<TrackerItemWidget> {
  TrackerState? _state;

  @override
  void dispose() {
    ///context都没了，也没有必要保留了
    if (_state != null) {
      _state!.removeContext(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _state = TrackerInheritedWidget.of(context)!;
    WidgetData item = WidgetData(
      context: context,
      id: widget.id,
      displayNotifier: widget.displayNotifier,
      trackerStrategy: widget.trackerStrategy,
    );
    _state!.addContext(item);

    return Container(
      child: AnimatedBuilder(
        animation: _state!,
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          final bool isInView = _state!.inView(widget.id);
          return widget.builder(context, isInView, child);
        },
      ),
    );
  }

  @override
  String toStringShort() {
    return describeIdentity(this) + ' id=${widget.id}';
  }
}

typedef Widget InViewNotifierWidgetBuilder(
  BuildContext context,
  bool isInView,
  Widget? child,
);
