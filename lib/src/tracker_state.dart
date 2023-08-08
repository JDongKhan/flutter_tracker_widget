import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tracker_widget/flutter_tracker_widget.dart';

import 'tracker_scroll_widget.dart';

/// @author jd

class TrackerState extends ChangeNotifier {
  TrackerState({
    required List<String> initHitIds,
    HitViewPortCondition? hitViewPortCondition,
  }) : _hitViewPortCondition = hitViewPortCondition {
    _contexts = Set<WidgetContextData>();
    _currentInViewIds.addAll(initHitIds);
  }

  ///scrollView context
  TrackerState? _parentState;
  BuildContext? _parentContext;
  Axis scrollDirection = Axis.vertical;

  ///当前在widget tree上对应的context
  late Set<WidgetContextData> _contexts;

  ///viewport height
  double vpHeight = 0.0;

  ///viewport width
  double vpWidth = 0.0;

  ///当前在viewport中间符合要求的ids
  List<String> _currentInViewIds = [];

  ///条件
  final HitViewPortCondition? _hitViewPortCondition;

  ///已经显示的 ids
  List<String> _displayedIds = [];

  ///in-view 数量
  int get inViewWidgetIdsLength => _currentInViewIds.length;

  ///element tree上context的数据
  int get numberOfContext => _contexts.length;

  ///可见的组件
  List<BuildContext?> get visibleContexts => _contexts.where((e) => e.visible).map((e) => e.context).toList();

  List<String?> get visibleIndexs => _contexts.where((e) => e.visible).map((e) => e.id).toList();

  void _setParentState(TrackerState state, BuildContext context) {
    _parentState = state;
    _parentContext = context;
  }

  ///Add the widget's context and an unique string id that needs to be notified.
  void addContext(WidgetContextData item) {
    //处理子父关系
    if (item.childState != null) {
      item.childState?._setParentState(this, item.context);
    }
    _contexts.removeWhere((d) => d.id == item.id);
    _contexts.add(item);
    _handleFirstRender(item);
  }

  void removeContext(String id) {
    _contexts.removeWhere((d) => d.id == id);
  }

  void clearDisplay() {
    _displayedIds.clear();
  }

  ///Checks if the widget with the `id` is currently in-view or not.
  bool inView(String id) {
    return _currentInViewIds.contains(id);
  }

  ///首次渲染处理逻辑，跟滚动有所区别
  void _handleFirstRender(
    WidgetContextData item, {
    bool ignoreParent = false,
  }) async {
    //等待帧渲染结束
    SchedulerBinding binding = SchedulerBinding.instance;
    await binding.endOfFrame;
    //因为是异步读取，可能widget已经从组件树上移除了
    if (!item.state.mounted) {
      debugPrint('组件${item.id}已释放');
      return;
    }

    //判断有没有在父state里面超出
    if (!ignoreParent && _parentContext != null && _parentState != null && !_parentState!._isInsideParentView(_parentContext!)) {
      return;
    }
    double viewportDimension = vpHeight;
    //处理水平的情况
    if (scrollDirection == Axis.horizontal) {
      viewportDimension = vpWidth;
    }
    if (_calculateOffset(item, viewportDimension, 0)) {
      ///处理display逻辑
      _handleDisplay(item, viewportDimension);

      ///如果外面指定了显示的id，这里就不处理了
      if (_currentInViewIds.isEmpty) {
        _handleInView(item, viewportDimension, () {
          ///因为正在build里面处理，所以想刷新得等一会
          Future.delayed(const Duration(milliseconds: 10), () {
            notifyListeners();
          });
        });
      }
    }
  }

  ///The listener that is called when the list view is scrolled.
  void onScroll(ScrollNotification notification) {
    // Iterate through each item to check
    // whether it is in the viewport
    _contexts.forEach((WidgetContextData item) {
      double viewportDimension = notification.metrics.viewportDimension;
      if (_calculateOffset(item, viewportDimension, notification.metrics.pixels)) {
        ///处理display逻辑
        _handleDisplay(item, viewportDimension);

        ///处理in view逻辑
        _handleInView(item, viewportDimension, () {
          notifyListeners();
        });
      }
    });
    // print('contexts:$_contexts');
    // print('visible:$visibleContexts');
  }

  ///计算偏移
  bool _calculateOffset(WidgetContextData item, double viewportDimension, double scrollOffset) {
    // Retrieve the RenderObject, linked to a specific item
    BuildContext c = item.context;
    final RenderObject? renderObject = c.findRenderObject();

    // If none was to be found, or if not attached, leave by now
    if (renderObject == null || !renderObject.attached) {
      return false;
    }

    //Retrieve the viewport related to the scroll area
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
    final RevealedOffset vpOffset = viewport.getOffsetToReveal(renderObject, 0.0);

    final Size size = renderObject.semanticBounds.size;
    //相对于窗口的偏移量
    final double offset = vpOffset.offset - scrollOffset;
    double deltaBottom = offset + size.height;

    if (scrollDirection == Axis.horizontal) {
      //distance from bottom of the widget to top of the viewport
      deltaBottom = offset + size.width;
    }

    item.offset = offset;
    item.offsetEnd = deltaBottom;
    return true;
  }

  ///是否在父组件内
  bool _isInsideParentView(BuildContext context) {
    // Retrieve the RenderObject, linked to a specific item
    RenderObject? renderObject = context.findRenderObject();
    // If none was to be found, or if not attached, leave by now
    if (renderObject == null || !renderObject.attached) {
      return false;
    }
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
    final RevealedOffset vpOffset = viewport.getOffsetToReveal(renderObject, 0.0);

    // Retrieve the dimensions of the item
    final Size size = renderObject.semanticBounds.size;
    //distance from top of the widget to top of the viewport
    final double offset = vpOffset.offset;
    double deltaBottom = offset + size.height;
    double viewPortDimension = vpHeight;
    //处理水平的情况
    if (scrollDirection == Axis.horizontal) {
      //distance from bottom of the widget to top of the viewport
      deltaBottom = offset + size.width;
      viewPortDimension = vpWidth;
    }
    if (offset > viewPortDimension || deltaBottom < 0) {
      return false;
    } else {
      return true;
    }
  }

  ///处理display逻辑
  void _handleDisplay(WidgetContextData item, double viewPortDimension) {
    // debugPrint(
    //     'id:${item.id},offset:${item.offset},offsetEnd:${item.offsetEnd},viewPortDimension:$viewPortDimension');
    if (item.offset > viewPortDimension || item.offsetEnd < 0) {
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
          item.displayNotifier!(item.context, item.id);
        } else if (item.childState != null) {
          debugPrint('发现${item.id}');

          ///子组件重新刷新
          item.childState?._refresh();
        }
      }
    }
  }

  ///处理in view逻辑
  void _handleInView(WidgetContextData item, double viewPortDimension, Function refreshFunction) {
    bool isInViewport = _hitViewPortCondition?.call(item.offset, item.offsetEnd, viewPortDimension) ?? false;
    if (isInViewport) {
      if (!_currentInViewIds.contains(item.id)) {
        _currentInViewIds.add(item.id);
        refreshFunction();
      }
    } else {
      if (_currentInViewIds.contains(item.id)) {
        _currentInViewIds.remove(item.id);
        refreshFunction();
      }
    }
  }

  ///刷新
  void _refresh() {
    _contexts.forEach((element) {
      _handleFirstRender(element, ignoreParent: true);
    });
  }
}

typedef void DisplayNotifier(
  BuildContext context,
  String id,
);

///跟踪策略
enum TrackerStrategy {
  only,

  ///只有一次
  every

  ///每一次
}

class WidgetContextData {
  WidgetContextData({
    required this.context,
    required this.id,
    required this.state,
    this.displayNotifier,
    this.trackerStrategy = TrackerStrategy.every,
    this.childState,
  });
  final BuildContext context;
  final String id;
  final DisplayNotifier? displayNotifier;
  final TrackerStrategy trackerStrategy;
  final TrackerState? childState;
  final State state;

  ///顶部居父widget的偏移
  double offset = 0;

  ///尾部居父widget的偏移
  double offsetEnd = 0;

  ///是否可见
  bool _visible = false;

  bool get visible => _visible;

  set visible(v) => _visible = v;

  @override
  String toString() {
    return describeIdentity(this) + ' id=$id' + ' visible:$visible';
  }
}
