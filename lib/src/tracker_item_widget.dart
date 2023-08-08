import 'package:flutter/foundation.dart';

/// @author jd
import 'package:flutter/material.dart';

import 'tracker_inherited_widget.dart';
import 'tracker_state.dart';

class TrackerItemWidget extends StatefulWidget {
  const TrackerItemWidget({
    Key? key,
    required this.id,
    this.builder,
    this.displayNotifier,
    this.trackerStrategy = TrackerStrategy.only,
    this.child,
    this.sliver = false,
  }) : super(key: key);

  // different with key
  final String id;

  final InViewNotifierWidgetBuilder? builder;

  //strategy
  final TrackerStrategy trackerStrategy;

  //callback
  final DisplayNotifier? displayNotifier;

  ///The child widget to pass to the builder.
  final Widget? child;

  ///child whether is sliver
  final bool sliver;

  @override
  State<StatefulWidget> createState() => _TrackerItemWidgetState();
}

class _TrackerItemWidgetState extends State<TrackerItemWidget> {
  TrackerState? _state;

  @override
  void dispose() {
    ///context都没了，也没有必要保留了
    _state?.removeContext(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _state = TrackerInheritedWidget.of(context)!;
    WidgetContextData item = WidgetContextData(
      context: context,
      state: this,
      id: widget.id,
      displayNotifier: widget.displayNotifier,
      trackerStrategy: widget.trackerStrategy,
    );
    _state!.addContext(item);
    if (widget.sliver) {
      return widget.child!;
    }
    return AnimatedBuilder(
      animation: _state!,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final bool isInView = _state!.inView(widget.id);
        if (widget.builder != null) {
          return widget.builder!(context, isInView, child);
        }
        if (child != null) {
          return child;
        }
        assert(child != null || widget.builder != null, 'child == null && widget.builder == null');
        return Container();
      },
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
