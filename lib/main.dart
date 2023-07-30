import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/collectibles_logic.dart';
import 'package:wonders/logic/locale_logic.dart';
import 'package:wonders/logic/met_api_logic.dart';
import 'package:wonders/logic/met_api_service.dart';
import 'package:wonders/logic/timeline_logic.dart';
import 'package:wonders/logic/unsplash_logic.dart';
import 'package:wonders/logic/wallpaper_logic.dart';
import 'package:wonders/logic/wonders_logic.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash screen up until app is finished bootstrapping
  // 保持本机启动屏幕，直到应用程序完成引导
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Start app
  registerSingletons();
  runApp(WondersApp());
  await appLogic.bootstrap();

  // Remove splash screen when bootstrap is complete
  // 引导完成后删除启动屏幕
  FlutterNativeSplash.remove();
}

/// Creates an app using the [MaterialApp.router] constructor and the global `appRouter`, an instance of [GoRouter].
/// 使用 [MaterialApp.router] 构造函数和全局 `appRouter`（[GoRouter] 的实例）创建一个应用程序。
class WondersApp extends StatelessWidget with GetItMixin {
  WondersApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final locale = watchX((SettingsLogic s) => s.currentLocale);
    return MaterialApp.router(
      routeInformationProvider: appRouter.routeInformationProvider,
      routeInformationParser: appRouter.routeInformationParser,
      locale: locale == null ? null : Locale(locale),
      debugShowCheckedModeBanner: false,
      routerDelegate: appRouter.routerDelegate,
      theme: ThemeData(fontFamily: $styles.text.body.fontFamily, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Create singletons (logic and services) that can be shared across the app.
/// 创建可以在应用程序中共享的单例（逻辑和服务）。
void registerSingletons() {
  // Top level app controller
  // 顶级应用程序控制器
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  // Wonders
  // 奇迹
  GetIt.I.registerLazySingleton<WondersLogic>(() => WondersLogic());
  // Timeline / Events
  GetIt.I.registerLazySingleton<TimelineLogic>(() => TimelineLogic());
  // Search
  GetIt.I.registerLazySingleton<MetAPILogic>(() => MetAPILogic());
  GetIt.I.registerLazySingleton<MetAPIService>(() => MetAPIService());
  // Settings
  // 设置
  GetIt.I.registerLazySingleton<SettingsLogic>(() => SettingsLogic());
  // Unsplash
  GetIt.I.registerLazySingleton<UnsplashLogic>(() => UnsplashLogic());
  // Collectibles
  // 收藏品
  GetIt.I.registerLazySingleton<CollectiblesLogic>(() => CollectiblesLogic());
  // Localizations
  // 本地化-实际是语言本地化
  GetIt.I.registerLazySingleton<LocaleLogic>(() => LocaleLogic());
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
/// 添加语法糖以快速访问应用程序中的主要“逻辑”控制器（也就是所谓的状态管理）
/// 我们故意不为服务创建快捷方式，以阻止它们直接在视图/小部件层中使用
AppLogic get appLogic => GetIt.I.get<AppLogic>();
WondersLogic get wondersLogic => GetIt.I.get<WondersLogic>();
TimelineLogic get timelineLogic => GetIt.I.get<TimelineLogic>();
SettingsLogic get settingsLogic => GetIt.I.get<SettingsLogic>();
UnsplashLogic get unsplashLogic => GetIt.I.get<UnsplashLogic>();
MetAPILogic get metAPILogic => GetIt.I.get<MetAPILogic>();
CollectiblesLogic get collectiblesLogic => GetIt.I.get<CollectiblesLogic>();
WallPaperLogic get wallpaperLogic => GetIt.I.get<WallPaperLogic>();
LocaleLogic get localeLogic => GetIt.I.get<LocaleLogic>();

/// Global helpers for readability
/// 可读性全局助手
AppLocalizations get $strings => localeLogic.strings;
AppStyle get $styles => WondersAppScaffold.style;
