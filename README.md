# flutter_tracker_widget

这是一个支持滚动播放和合理曝光的组件

## Getting Started

1、pubspec.yaml 

```dart
flutter_tracker_widget: any
```



2、install 

```
flutter pub get
```



3、import

```dart
import 'package:flutter_tracker_widget/flutter_tracker_widget.dart'
```



4、usage

```dart
TrackerScrollWidget(
          initialInViewIds: ['0'],
          isInViewPortCondition: (
            double deltaTop,
            double deltaBottom,
            double viewPortDimension,
          ) {
            return deltaTop < (0.5 * viewPortDimension) &&
                deltaBottom > (0.5 * viewPortDimension);
          },
          child: ListView.builder(
            itemBuilder: (c, index) {
              return TrackerItemWidget(
                id: '$index',
                child: Container(
                  height: 200,
                  child: Center(
                      child: Text(
                    '$index',
                    style: TextStyle(color: Colors.white),
                  )),
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
          ),
        )
```



![demo png](https://github.com/JDongKhan/flutter_tracker_widget/blob/main/1.gif)


借鉴于:**inview_notifier_list**,做了大量修改



**不同的地方：**

1、在滚动结束才处理cell可见的逻辑，避免滚动中影响性能



2、增加曝光的逻辑，支持滚动过程中只曝光一次或每次都曝光

```dart
///跟踪策略
enum TrackerStrategy {
  only,

  ///只有一次
  every

  ///每一次
}

```



3、首次进入也会走曝光和inview逻辑



4、更合理的释放机制



5、优化inview_notifier_list逻辑

