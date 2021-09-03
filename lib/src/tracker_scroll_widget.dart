/// @author jd
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stream_transform/stream_transform.dart';

import 'tracker_inherited_widget.dart';
import 'tracker_state.dart';

///父类
class TrackerScrollWidget extends StatefulWidget {
  TrackerScrollWidget({
    Key? key,
    required this.child,
    this.initHitIds = const [],
    this.throttleDuration = const Duration(milliseconds: 200),
    required this.hitViewPortCondition,
  })   : scrollDirection = child.scrollDirection,
        super(key: key);

  ///The String list of ids of the child widgets that should be initialized as inView
  ///when the list view is built for the first time.
  final List<String> initHitIds;

  ///The widget that should be displayed in the [InViewNotifier].
  final ScrollView child;

  ///The duration to be used for throttling the scroll notification.
  ///Defaults to 200 milliseconds.
  final Duration throttleDuration;

  ///The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  ///The function that defines the area within which the widgets should be notified
  ///as inView.
  final HitViewPortCondition hitViewPortCondition;

  @override
  _TrackerScrollWidgetState createState() => _TrackerScrollWidgetState();
}

class _TrackerScrollWidgetState extends State<TrackerScrollWidget> {
  TrackerState? _trackerState;
  StreamController<ScrollNotification>? _streamController;

  @override
  void initState() {
    super.initState();
    _initializeInViewState();
    _startListening();
  }

  @override
  void didUpdateWidget(TrackerScrollWidget oldWidget) {
    if (oldWidget.throttleDuration != widget.throttleDuration) {
      //when throttle duration changes, close the existing stream controller if exists
      //and start listening to a stream that is throttled by new duration.
      _streamController?.close();
      _startListening();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _trackerState?.dispose();
    _trackerState = null;
    _streamController?.close();
    super.dispose();
  }

  void _startListening() {
    _streamController = StreamController<ScrollNotification>();
    _streamController!.stream
        .audit(widget.throttleDuration)
        .listen(_trackerState!.onScroll);
  }

  void _initializeInViewState() {
    _trackerState = TrackerState(
      initHitIds: widget.initHitIds,
      hitViewPortCondition: widget.hitViewPortCondition,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    late bool isScrollDirection;
    //the direction of user scroll up, down, left, right.
    final Axis scrollDirection = notification.metrics.axis;
    // print('scrollDirection:${notification.metrics}');
    switch (widget.scrollDirection) {
      case Axis.vertical:
        isScrollDirection = scrollDirection == Axis.vertical;
        break;
      case Axis.horizontal:
        isScrollDirection = scrollDirection == Axis.horizontal;
        break;
    }

    //when user is not scrolling
    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      //Keeps only the last number contexts provided by user. This prevents overcalculation
      //by iterating over non visible widget contexts in scroll listener
      // _inViewState!.removeContexts(widget.contextCacheCount);

      // if (!_streamController!.isClosed && isScrollDirection) {
      //   _streamController!.add(notification);
      // }
    }

    ///一切都是为了性能，滚动结束在处理
    if (notification is ScrollEndNotification) {
      if (!_streamController!.isClosed && isScrollDirection) {
        _streamController!.add(notification);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        ///viewport的高度
        _trackerState!.vpHeight = constraints.maxHeight;
        return TrackerInheritedWidget(
          inViewState: _trackerState,
          child: NotificationListener<ScrollNotification>(
            child: widget.child,
            onNotification: _onScroll,
          ),
        );
      },
    );
  }
}

///The function that defines the area within which the widgets should be notified
///as inView.
typedef bool HitViewPortCondition(
  double deltaTop,
  double deltaBottom,
  double viewPortDimension,
);
