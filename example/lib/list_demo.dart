import 'package:flutter/material.dart';
import 'package:flutter_tracker_widget/flutter_tracker_widget.dart';

/// @author jd

class ListDemo extends StatelessWidget {
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
        title: Text('List Demo'),
      ),
      body: TrackerScrollWidget(
        initialInViewIds: ['0'],
        isInViewPortCondition: (
          double deltaTop,
          double deltaBottom,
          double viewPortDimension,
        ) {
          ///判断是否出于中间
          // print('deltaTop:$deltaTop - deltaBottom:$deltaBottom - viewPortDimension:$viewPortDimension');
          return deltaTop < (0.5 * viewPortDimension) &&
              deltaBottom > (0.5 * viewPortDimension);
        },
        child: _listWidget(),
      ),
    );
  }

  ///list demo
  Widget _listWidget() {
    return ListView.builder(
      itemBuilder: (c, index) {
        return TrackerItemWidget(
          id: '$index',
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
          displayNotifier: (
            BuildContext context,
            bool visiable,
            String id,
          ) {
            print('id:$id - index:$index - visiable:$visiable');
          },
          builder: (
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
          },
        );
      },
      itemCount: 100,
    );
  }
}
