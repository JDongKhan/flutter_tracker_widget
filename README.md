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
                  String id,
                ) {
                  print('开始曝光了 { id:$id - index:$index }');
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



**主要功能:**



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

TrackerStrategy.only下，曝光不会重复

```shell

flutter: 开始曝光了 { id:first - visiable:true }
flutter: 开始曝光了 { id:second - visiable:true }
flutter: 开始曝光了 { id:0 - visiable:true }
flutter: 开始曝光了 { id:1 - visiable:true }
flutter: 开始曝光了 { id:2 - visiable:true }
flutter: 开始曝光了 { id:3 - visiable:true }
flutter: 开始曝光了 { id:5 - visiable:true }
flutter: 开始曝光了 { id:6 - visiable:true }
flutter: 开始曝光了 { id:7 - visiable:true }
flutter: 开始曝光了 { id:8 - visiable:true }
flutter: 开始曝光了 { id:9 - visiable:true }
flutter: 开始曝光了 { id:4 - visiable:true }
```

TrackerStrategy.every下，曝光会重复

```
flutter: 开始曝光了 { id:0 - index:0 - visiable:true }
flutter: 开始曝光了 { id:1 - index:1 - visiable:true }
flutter: 开始曝光了 { id:2 - index:2 - visiable:true }
flutter: 开始曝光了 { id:3 - index:3 - visiable:true }
flutter: 开始曝光了 { id:4 - index:4 - visiable:true }
flutter: 开始曝光了 { id:5 - index:5 - visiable:true }
flutter: 开始曝光了 { id:0 - index:0 - visiable:true }

```



3、首次进入也会走曝光和hit逻辑



如果想指定首次命中的view，可以使用initHitIds将指定的id传入



```
比如：initHitIds: ['0'],
```



不传，默认会调用hitViewPortCondition去计算命中的view



4、方便获取visibleContexts



底层维护一个context的list，便于获取scrollview中可见的RenderObject



5、更合理的释放机制