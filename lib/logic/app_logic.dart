import 'dart:async';
import 'dart:ui';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/platform_info.dart';
import 'package:wonders/ui/common/modals/fullscreen_video_viewer.dart';
import 'package:wonders/ui/common/utils/page_routes.dart';

class AppLogic {
  /// Indicates to the rest of the app that bootstrap has not completed.
  /// The router will use this to prevent redirects while bootstrapping.
  /// 向应用程序的其余部分指示引导尚未完成。
  /// 路由器将使用它来防止引导时重定向。
  bool isBootstrapComplete = false;

  /// Indicates which orientations the app will allow be default. Affects Android/iOS devices only.
  /// Defaults to both landscape (hz) and portrait (vt)
  /// 指示应用程序默认允许的方向。仅影响 Android/iOS 设备。
  /// 默认为横向 (hz) 和纵向 (vt)
  List<Axis> supportedOrientations = [Axis.vertical, Axis.horizontal];

  /// Allow a view to override the currently supported orientations. For example, [FullscreenVideoViewer] always wants to enable both landscape and portrait.
  /// If a view sets this override, they are responsible for setting it back to null when finished.
  /// 允许视图覆盖当前支持的方向。例如，[FullscreenVideoViewer] 总是希望同时启用横向和纵向。
  /// 如果视图设置了此覆盖，则它们负责在完成后将其设置回 null。
  List<Axis>? _supportedOrientationsOverride;
  set supportedOrientationsOverride(List<Axis>? value) {
    if (_supportedOrientationsOverride != value) {
      _supportedOrientationsOverride = value;
      _updateSystemOrientation();
    }
  }

  /// Initialize the app and all main actors.
  /// Loads settings, sets up services etc.
  /// 初始化应用程序和所有主要参与者。
  /// 加载设置、设置服务等。
  Future<void> bootstrap() async {
    debugPrint('bootstrap start...');
    // Set min-sizes for desktop apps
    // 设置桌面应用程序的最小尺寸
    if (PlatformInfo.isDesktop) {
      await DesktopWindow.setMinWindowSize($styles.sizes.minAppSize);
    }

    // Load any bitmaps the views might need
    // 加载视图可能需要的任何位图
    await AppBitmaps.init();

    // Set preferred refresh rate to the max possible (the OS may ignore this)
    // 将首选刷新率设置为最大可能（操作系统可能会忽略此）
    if (PlatformInfo.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    // Settings
    await settingsLogic.load();

    // Localizations
    // 语言本地化
    await localeLogic.load();

    // Wonders Data
    wondersLogic.init();

    // Events
    // 活动
    timelineLogic.init();

    // Collectibles
    // 收藏品
    await collectiblesLogic.load();

    // Flag bootStrap as complete
    // 将 bootStrap 标记为完成
    isBootstrapComplete = true;

    // Load initial view (replace empty initial view which is covered by a native splash screen)
    // 加载初始视图（替换被本机启动屏幕覆盖的空初始视图）
    bool showIntro = settingsLogic.hasCompletedOnboarding.value == false;
    if (showIntro) {
      appRouter.go(ScreenPaths.intro);
    } else {
      appRouter.go(ScreenPaths.home);
    }
  }

  Future<T?> showFullscreenDialogRoute<T>(BuildContext context, Widget child, {bool transparent = false}) async {
    return await Navigator.of(context).push<T>(
      PageRoutes.dialog<T>(child, duration: $styles.times.pageTransition),
    );
  }

  /// Called from the UI layer once a MediaQuery has been obtained
  /// 获得 MediaQuery 后从 UI 层调用
  void handleAppSizeChanged() {
    /// Disable landscape layout on smaller form factors
    /// 在较小的外形尺寸上禁用横向布局
    bool isSmall = display.size.shortestSide / display.devicePixelRatio < 600;
    supportedOrientations = isSmall ? [Axis.vertical] : [Axis.vertical, Axis.horizontal];
    _updateSystemOrientation();
  }

  Display get display => PlatformDispatcher.instance.displays.first;

  bool shouldUseNavRail() => display.size.width > display.size.height && display.size.height > 250;

  /// Enable landscape, portrait or both. Views can call this method to override the default settings.
  /// For example, the [FullscreenVideoViewer] always wants to enable both landscape and portrait.
  /// If a view overrides this, it is responsible for setting it back to [supportedOrientations] when disposed.
  /// 启用横向、纵向或两者。视图可以调用此方法来覆盖默认设置。
  /// 例如，[FullscreenVideoViewer] 总是希望同时启用横向和纵向。
  /// 如果视图覆盖了它，它负责在处理时将其设置回 [supportedOrientations]。
  void _updateSystemOrientation() {
    final axisList = _supportedOrientationsOverride ?? supportedOrientations;
    //debugPrint('updateDeviceOrientation, supportedAxis: $axisList');
    final orientations = <DeviceOrientation>[];
    if (axisList.contains(Axis.vertical)) {
      orientations.addAll([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (axisList.contains(Axis.horizontal)) {
      orientations.addAll([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    SystemChrome.setPreferredOrientations(orientations);
  }
}

class AppImageCache extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    this.imageCache.maximumSizeBytes = 250 << 20; // 250mb
    return super.createImageCache();
  }
}
