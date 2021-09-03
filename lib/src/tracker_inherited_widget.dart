/// @author jd
import 'package:flutter/widgets.dart';

import 'tracker_state.dart';

class TrackerInheritedWidget extends InheritedWidget {
  final TrackerState? inViewState;
  final Widget child;

  static TrackerState? of(BuildContext context) {
    final TrackerInheritedWidget widget = context
        .getElementForInheritedWidgetOfExactType<TrackerInheritedWidget>()!
        .widget as TrackerInheritedWidget;
    return widget.inViewState;
  }

  TrackerInheritedWidget({Key? key, this.inViewState, required this.child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(TrackerInheritedWidget oldWidget) => false;
}
