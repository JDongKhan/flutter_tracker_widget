import 'package:flutter/material.dart';
import 'package:flutter_tracker_widget/flutter_tracker_widget.dart';

/// @author jd
class CustomScrollDemo extends StatelessWidget {
  List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Scroll Demo'),
      ),
      body: TrackerScrollWidget(
        initialInViewIds: ['first'],
        isInViewPortCondition: (
          double deltaTop,
          double deltaBottom,
          double viewPortDimension,
        ) {
          // print('deltaTop:$deltaTop - deltaBottom:$deltaBottom - viewPortDimension:$viewPortDimension');
          ///判断是否出于中间
          return deltaTop < (0.5 * viewPortDimension) &&
              deltaBottom > (0.5 * viewPortDimension);
        },
        child: _customScrollView(),
      ),
    );
  }

  ///customscroll demo
  Widget _customScrollView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TrackerItemWidget(
            id: 'first',
            displayNotifier: _displayNotifier,
            child: Container(
              height: 100,
              color: Colors.red,
              child: Center(
                child: Text('我比较特殊'),
              ),
            ),
            builder: _inView,
          ),
        ),
        SliverToBoxAdapter(
          child: TrackerItemWidget(
            id: 'second',
            builder: _inView,
            displayNotifier: _displayNotifier,
            child: Container(
              color: Colors.blue,
              height: 100,
              child: Center(
                child: Text('我也比较特殊'),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return TrackerItemWidget(
              id: '$index',
              builder: _inView,
              displayNotifier: _displayNotifier,
              child: Container(
                height: 200,
                color: _colors[index % 7],
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }, childCount: 10),
        ),
      ],
    );
  }

  Widget _inView(
    BuildContext context,
    bool isInView,
    Widget child,
  ) {
    return Stack(children: [
      child,
      Positioned(
        right: 0,
        top: 0,
        child: Text(
          isInView ? '显示' : '',
          style: TextStyle(color: Colors.white),
        ),
      )
    ]);
  }

  ///曝光
  void _displayNotifier(
    BuildContext context,
    bool visiable,
    String id,
  ) {
    print('id:$id - visiable:$visiable');
  }
}
