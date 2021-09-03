import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'tracker_scroll_widget.dart';

/// @author jd

class TrackerState extends ChangeNotifier {
  TrackerState({
    required List<String> initHitIds,
    bool Function(double, double, double)? hitViewPortCondition,
  }) : _hitViewPortCondition = hitViewPortCondition {
    _contexts = Set<WidgetData>();
    _currentInViewIds.addAll(initHitIds);
  }

  ///当前在widget tree上对应的context
  late Set<WidgetData> _contexts;

  ///viewport height
  double vpHeight = 0.0;

  ///当前在viewport中间符合要求的ids
  List<String> _currentInViewIds = [];

  ///条件
  final HitViewPortCondition? _hitViewPortCondition;

  //已经显示的 ids
  List<String> _displayedIds = [];

  ///in-view 数量
  int get inViewWidgetIdsLength => _currentInViewIds.length;

  ///tree上context的数据
  int get numberOfContext => _contexts.length;

  ///可见的组件
  List<BuildContext?> get visibleContexts =>
      _contexts.where((e) => e.visible).map((e) => e.context).toList();

  ///Add the widget's context and an unique string id that needs to be notified.
  void addContext(WidgetData item) {
    _contexts.removeWhere((d) => d.id == item.id);
    _contexts.add(item);
    _handleFirstRender(item);
  }

  void removeContext(String id) {
    _contexts.removeWhere((d) => d.id == id);
  }

  ///Checks if the widget with the `id` is currently in-view or not.
  bool inView(String id) {
    return _currentInViewIds.contains(id);
  }

  ///首次渲染处理逻辑，跟滚动有所区别
  void _handleFirstRender(WidgetData item) async {
    //等待帧渲染结束
    await SchedulerBinding.instance!.endOfFrame;
    // Retrieve the RenderObject, linked to a specific item
    final RenderObject? renderObject = item.context!.findRenderObject();
    // If none was to be found, or if not attached, leave by now
    if (renderObject == null || !renderObject.attached) {
      return;
    }
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(renderObject)!;
    final double vpHeight = this.vpHeight;
    final RevealedOffset vpOffset =
        viewport.getOffsetToReveal(renderObject, 0.0);

    // Retrieve the dimensions of the item
    final Size size = renderObject.semanticBounds.size;

    //distance from top of the widget to top of the viewport
    final double deltaTop = vpOffset.offset;

    //distance from bottom of the widget to top of the viewport
    final double deltaBottom = deltaTop + size.height;

    ///处理display逻辑
    _handleDisplay(item, deltaTop, deltaBottom, vpHeight);

    ///如果外面指定了显示的id，这里就不处理了
    if (_currentInViewIds.isEmpty) {
      _handleInView(item, deltaTop, deltaBottom, vpHeight, () {
        ///因为正在build里面处理，所以想刷新得等一会
        Future.delayed(const Duration(milliseconds: 1), () {
          notifyListeners();
        });
      });
    }
  }

  ///The listener that is called when the list view is scrolled.
  void onScroll(ScrollNotification notification) {
    // Iterate through each item to check
    // whether it is in the viewport
    _contexts.forEach((WidgetData item) {
      // Retrieve the RenderObject, linked to a specific item
      final RenderObject? renderObject = item.context!.findRenderObject();

      // If none was to be found, or if not attached, leave by now
      if (renderObject == null || !renderObject.attached) {
        return;
      }

      //Retrieve the viewport related to the scroll area
      final RenderAbstractViewport viewport =
          RenderAbstractViewport.of(renderObject)!;
      final double vpHeight = notification.metrics.viewportDimension;
      final RevealedOffset vpOffset =
          viewport.getOffsetToReveal(renderObject, 0.0);

      final Size size = renderObject.semanticBounds.size;

      final double deltaTop = vpOffset.offset - notification.metrics.pixels;

      final double deltaBottom = deltaTop + size.height;

      ///处理display逻辑
      _handleDisplay(item, deltaTop, deltaBottom, vpHeight);

      ///处理in view逻辑
      _handleInView(item, deltaTop, deltaBottom, vpHeight, () {
        notifyListeners();
      });
    });
    // print('contexts:$_contexts');
    // print('visible:$visibleContexts');
  }

  ///处理display逻辑
  void _handleDisplay(WidgetData item, double deltaTop, double deltaBottom,
      double viewPortDimension) {
    if (deltaTop > vpHeight || deltaBottom < 0) {
      item.visible = false;

      ///不在屏幕内
      if (item.trackerStrategy == TrackerStrategy.every) {
        ///清除记录
        if (_displayedIds.contains(item.id)) {
          _displayedIds.remove(item.id);
        }
      }
    } else {
      item.visible = true;
      if (!_displayedIds.contains(item.id)) {
        _displayedIds.add(item.id);
        if (item.displayNotifier != null) {
          item.displayNotifier!(item.context!, true, item.id);
        }
      }
    }
  }

  ///处理in view逻辑
  void _handleInView(WidgetData item, double deltaTop, double deltaBottom,
      double viewPortDimension, Function refreshFuncation) {
    bool isInViewport = _hitViewPortCondition!(deltaTop, deltaBottom, vpHeight);
    if (isInViewport) {
      if (!_currentInViewIds.contains(item.id)) {
        _currentInViewIds.add(item.id);
        if (refreshFuncation != null) {
          refreshFuncation();
        }
      }
    } else {
      if (_currentInViewIds.contains(item.id)) {
        _currentInViewIds.remove(item.id);
        if (refreshFuncation != null) {
          refreshFuncation();
        }
      }
    }
  }
}

typedef void DisplayNotifier(
  BuildContext context,
  bool display,
  String id,
);

///跟踪策略
enum TrackerStrategy {
  only,

  ///只有一次
  every

  ///每一次
}

class WidgetData {
  WidgetData({
    required this.context,
    required this.id,
    this.displayNotifier,
    this.trackerStrategy = TrackerStrategy.every,
  });
  final BuildContext? context;
  final String id;
  final DisplayNotifier? displayNotifier;
  final TrackerStrategy trackerStrategy;

  ///是否可见
  bool _visible = false;

  bool get visible => _visible;

  set visible(v) => _visible = v;

  @override
  String toString() {
    return describeIdentity(this) + ' id=$id' + ' visible:$visible';
  }
}
