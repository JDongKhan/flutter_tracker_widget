/// @author jd
import 'package:flutter/widgets.dart';

import 'tracker_state.dart';

class TrackerInheritedWidget extends InheritedWidget {
  final TrackerState? inViewState;
  final Widget child;

  ///获取TrackerState，便于你获取里面的数据
  static TrackerState? of(BuildContext context) {
    final Widget? widget = context
        .getElementForInheritedWidgetOfExactType<TrackerInheritedWidget>()
        ?.widget;
    if (widget != null) {
      TrackerInheritedWidget inheritedWidget = widget as TrackerInheritedWidget;
      return inheritedWidget.inViewState;
    }
    return null;
  }

  ///获取TrackerState，便于你获取里面的数据
  static TrackerState? root(BuildContext context) {
    final TrackerInheritedWidget? widget =
        context.findAncestorWidgetOfExactType<TrackerInheritedWidget>();
    return widget?.inViewState;
  }

  //获取可见的context数组
  static List<BuildContext?>? visibleContexts(BuildContext context) {
    TrackerState? state = TrackerInheritedWidget.of(context);
    return state?.visibleContexts;
  }

  ///获取可见的index数组
  static List<String?>? visibleIndexs(BuildContext context) {
    TrackerState? state = TrackerInheritedWidget.of(context);
    return state?.visibleIndexs;
  }

  TrackerInheritedWidget({Key? key, this.inViewState, required this.child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(TrackerInheritedWidget oldWidget) => false;
}
