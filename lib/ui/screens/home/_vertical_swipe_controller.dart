part of 'wonders_home_screen.dart';

class _VerticalSwipeController {
  _VerticalSwipeController(this.ticker, this.onSwipeComplete);
  final TickerProvider ticker;
  final swipeAmt = ValueNotifier<double>(0);
  final isPointerDown = ValueNotifier<bool>(false);
  late final swipeReleaseAnim = AnimationController(vsync: ticker)..addListener(handleSwipeReleaseAnimTick);
  final double _pullToViewDetailsThreshold = 150;
  final VoidCallback onSwipeComplete;

  /// When the _swipeReleaseAnim plays, sync its value to _swipeUpAmt
  /// 当 _swipeReleaseAnim 播放时，将其值同步到 _swipeUpAmt
  void handleSwipeReleaseAnimTick() => swipeAmt.value = swipeReleaseAnim.value;
  void handleTapDown() => isPointerDown.value = true;
  void handleTapCancelled() => isPointerDown.value = false;

  void handleVerticalSwipeCancelled() {
    swipeReleaseAnim.duration = swipeAmt.value.seconds * .5;
    swipeReleaseAnim.reverse(from: swipeAmt.value);
    isPointerDown.value = false;
  }

  void handleVerticalSwipeUpdate(DragUpdateDetails details) {
    if (swipeReleaseAnim.isAnimating) swipeReleaseAnim.stop();

    isPointerDown.value = true;
    double value = (swipeAmt.value - details.delta.dy / _pullToViewDetailsThreshold).clamp(0, 1);
    if (value != swipeAmt.value) {
      swipeAmt.value = value;
      if (swipeAmt.value == 1) {
        onSwipeComplete();
      }
    }

    //print(_swipeUpAmt.value);
  }

  /// Utility method to wrap a couple of ValueListenableBuilders and pass the values into a builder methods.
  /// Saves the UI some boilerplate when subscribing to changes.
  /// 用于包装几个 ValueListenableBuilder 并将值传递到构建器方法的实用方法。
  /// 订阅更改时，为 UI 保存一些样板文件。
  Widget buildListener(
      {required Widget Function(double swipeUpAmt, bool isPointerDown, Widget? child) builder, Widget? child}) {
    return ValueListenableBuilder<double>(
      valueListenable: swipeAmt,
      builder: (_, swipeAmt, __) => ValueListenableBuilder<bool>(
        valueListenable: isPointerDown,
        builder: (_, isPointerDown, __) {
          return builder(swipeAmt, isPointerDown, child);
        },
      ),
    );
  }

  /// Utility method to wrap a gesture detector and wire up the required handlers.
  /// 用于包装手势检测器并连接所需处理程序的实用方法。
  Widget wrapGestureDetector(Widget child, {Key? key}) => GestureDetector(
      key: key,
      excludeFromSemantics: true,
      onTapDown: (_) => handleTapDown(),
      onTapUp: (_) => handleTapCancelled(),
      onVerticalDragUpdate: handleVerticalSwipeUpdate,
      onVerticalDragEnd: (_) => handleVerticalSwipeCancelled(),
      onVerticalDragCancel: handleVerticalSwipeCancelled,
      behavior: HitTestBehavior.translucent,
      child: child);

  void dispose(){
    swipeAmt.dispose();
    isPointerDown.dispose();
    swipeReleaseAnim.dispose();
  }
}
