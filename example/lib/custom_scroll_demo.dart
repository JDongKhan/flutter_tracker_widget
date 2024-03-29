import 'package:flutter/material.dart';
import 'package:flutter_tracker_widget/flutter_tracker_widget.dart';

/// @author jd
class CustomScrollDemo extends StatelessWidget {
  List<Color> _colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Scroll Demo'),
      ),
      body: TrackerScrollWidget(
        hitViewPortCondition: (double deltaTop, double deltaBottom, double viewPortDimension) {
          print('deltaTop:$deltaTop - deltaBottom:$deltaBottom - viewPortDimension:$viewPortDimension');
          return deltaTop < (0.5 * viewPortDimension) && deltaBottom > (0.5 * viewPortDimension);

          ///判断是否出于中间
          // return deltaTop < (0.5 * viewPortDimension) &&
          //     deltaBottom > (0.5 * viewPortDimension);
        },
        child: _customScrollView(),
      ),
    );
  }

  ///customscroll demo
  ScrollView _customScrollView() {
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
        TrackerItemWidget(
          id: 'third',
          sliver: true,
          displayNotifier: _displayNotifier,
          child: SliverToBoxAdapter(
            child: Text('我比较特殊'),
          ),
        ),
        TrackerItemWidget(
          id: 'forth',
          sliver: true,
          displayNotifier: _displayNotifier,
          child: SliverToBoxAdapter(
            child: Container(
              height: 1000,
              alignment: Alignment.center,
              color: Colors.green,
              child: Text('我变高后会占用别人曝光的机会'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: TrackerScrollWidget(
              id: 'fifth',
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, idx) {
                  return TrackerItemWidget(
                    id: 'list_$idx',
                    builder: _inView,
                    key: UniqueKey(),
                    displayNotifier: (c, id) {
                      print('开始曝光了 horizontal { id:$id }');
                    },
                    child: Container(
                      width: 100,
                      child: Center(child: Text('$idx')),
                    ),
                  );
                },
                itemCount: 20,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            },
            childCount: 100,
          ),
        ),
      ],
    );
  }

  Widget _inView(BuildContext context, bool isInView, Widget? child) {
    return Stack(
      children: [
        child!,
        Positioned(
          right: 0,
          top: 0,
          child: Text(
            isInView ? '显示' : '',
            style: TextStyle(color: Colors.white),
          ),
        )
      ],
    );
  }

  ///曝光
  void _displayNotifier(BuildContext context, String id) {
    print('开始曝光了 { id:$id }');
  }
}
