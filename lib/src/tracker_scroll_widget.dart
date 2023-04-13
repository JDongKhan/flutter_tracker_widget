/// @author jd
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stream_transform/stream_transform.dart';

import 'tracker_inherited_widget.dart';
import 'tracker_state.dart';

enum ScrollStrategy {
  all,
  end,
}

typedef ScrollWidgetBuilder = ScrollView Function(BuildContext context);

///父类
class TrackerScrollWidget extends StatefulWidget {
  TrackerScrollWidget({
    Key? key,
    required this.child,
    this.id,
    this.initHitIds = const [],
    this.throttleDuration = const Duration(milliseconds: 200),
    this.hitViewPortCondition,
    this.scrollStrategy = ScrollStrategy.end,
    this.trackerStrategy = TrackerStrategy.only,
  }) : super(key: key);

  ///The String list of ids of the child widgets that should be initialized as inView
  ///when the list view is built for the first time.
  final List<String> initHitIds;

  ///The widget that should be displayed in the [InViewNotifier].
  final ScrollView child;

  ///The duration to be used for throttling the scroll notification.
  ///Defaults to 200 milliseconds.
  final Duration throttleDuration;

  ///The function that defines the area within which the widgets should be notified
  ///as inView.
  final HitViewPortCondition? hitViewPortCondition;

  ///scroll strategy
  final ScrollStrategy scrollStrategy;

  ///当TrackerScrollWidget出现嵌套时，需要指定id
  final String? id;

  ///曝光策略，只有一次、每次都曝光
  final TrackerStrategy trackerStrategy;

  @override
  _TrackerScrollWidgetState createState() => _TrackerScrollWidgetState();
}

class _TrackerScrollWidgetState extends State<TrackerScrollWidget> {
  TrackerState? _parentState;
  TrackerState? _trackerState;
  StreamController<ScrollNotification>? _streamController;
  Axis _scrollDirection = Axis.vertical;

  @override
  void initState() {
    super.initState();
    _trackerState = TrackerState(
      initHitIds: widget.initHitIds,
      hitViewPortCondition: widget.hitViewPortCondition,
    );
    _scrollDirection = widget.child.scrollDirection;
    _trackerState?.scrollDirection = _scrollDirection;
    _startListening();
  }

  ///监听滚动
  void _startListening() {
    _streamController = StreamController<ScrollNotification>();
    _streamController!.stream
        .audit(widget.throttleDuration)
        .listen(_trackerState!.onScroll);
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

    ///context都没了，也没有必要保留了
    if (widget.id != null) {
      _parentState?.removeContext(widget.id!);
    }
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    //the direction of user scroll up, down, left, right.
    final Axis scrollDirection = notification.metrics.axis;
    bool isScrollDirection = _scrollDirection == scrollDirection;
    // print('scrollDirection:${notification.metrics}');
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
    if (widget.scrollStrategy == ScrollStrategy.end) {
      if (notification is! ScrollEndNotification) {
        return false;
      }
    }
    if (!_streamController!.isClosed && isScrollDirection) {
      _streamController!.add(notification);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ScrollView child = widget.child;
    _parentState = TrackerInheritedWidget.of(context);
    if (_parentState != null) {
      assert(widget.id != null, 'id can not null');
      WidgetContextData item = WidgetContextData(
        context: context,
        state: this,
        id: widget.id!,
        trackerStrategy: widget.trackerStrategy,
        childState: _trackerState,
      );
      _parentState?.addContext(item);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        ///viewport的高度
        _trackerState?.vpHeight = constraints.maxHeight;
        _trackerState?.vpWidth = constraints.maxWidth;
        return TrackerInheritedWidget(
          inViewState: _trackerState,
          child: NotificationListener<ScrollNotification>(
            child: child,
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
  double offset,
  double offsetEnd,
  double viewPortDimension,
);
