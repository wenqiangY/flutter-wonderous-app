import 'package:wonders/common_libs.dart';
import 'package:wonders/ui/common/app_scroll_behavior.dart';

/// 页面骨架 
class WondersAppScaffold extends StatelessWidget {
  const WondersAppScaffold({Key? key, required this.child}) : super(key: key);
  final Widget child;
  static AppStyle get style => _style;
  static AppStyle _style = AppStyle();

  @override
  Widget build(BuildContext context) {
    // Listen to the device size, and update AppStyle when it changes
    // 监听设备尺寸，并在发生变化时更新AppStyle
    MediaQuery.of(context);
    appLogic.handleAppSizeChanged();
    // Set default timing for animations in the app
    // 设置应用程序中动画的默认时间
    Animate.defaultDuration = _style.times.fast;
    // Create a style object that will be passed down the widget tree
    // 创建一个将在小部件树中传递的样式对象
    _style = AppStyle(screenSize: context.sizePx);
    return KeyedSubtree(
      key: ValueKey($styles.scale),
      child: Theme(
        data: $styles.colors.toThemeData(),
        // Provide a default texts style to allow Hero's to render text properly
        // 提供默认文本样式以允许 Hero's 正确渲染文本
        child: DefaultTextStyle(
          style: $styles.text.body,
          // Use a custom scroll behavior across entire app
          // 在整个应用程序中使用自定义滚动行为
          child: ScrollConfiguration(
            behavior: AppScrollBehavior(),
            child: child,
          ),
        ),
      ),
    );
  }
}
