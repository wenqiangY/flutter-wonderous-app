import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/wonder_data.dart';
import 'package:wonders/ui/common/app_icons.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/controls/app_page_indicator.dart';
import 'package:wonders/ui/common/gradient_container.dart';
import 'package:wonders/ui/common/themed_text.dart';
import 'package:wonders/ui/common/utils/app_haptics.dart';
import 'package:wonders/ui/screens/home_menu/home_menu.dart';
import 'package:wonders/ui/wonder_illustrations/common/animated_clouds.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_illustration.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_illustration_config.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_title_text.dart';

part '_vertical_swipe_controller.dart';
part 'widgets/_animated_arrow_button.dart';

class HomeScreen extends StatefulWidget with GetItStatefulWidgetMixin {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Shows a horizontally scrollable list PageView sandwiched between Foreground and Background layers
/// arranged in a parallax style.
/// 显示夹在前景层和背景层之间的水平可滚动列表 PageView
/// 以视差风格排列。
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  List<WonderData> get _wonders => wondersLogic.all;
  bool _isMenuOpen = false;

  /// Set initial wonderIndex
  /// 设置初始 WonderIndex
  late int _wonderIndex = 0;
  int get _numWonders => _wonders.length;

  /// Used to polish the transition when leaving this page for the details view.
  /// Used to capture the _swipeAmt at the time of transition, and freeze the wonder foreground in place as we transition away.
  /// 用于完善离开此页面进入详细信息视图时的过渡。
  /// 用于在转换时捕获 _swipeAmt，并在我们转换离开时将奇迹前景冻结在适当的位置。
  double? _swipeOverride;

  /// Used to let the foreground fade in when this view is returned to (from details)
  /// 用于在返回此视图时让前景淡入（来自细节）
  bool _fadeInOnNextBuild = false;

  /// All of the items that should fade in when returning from details view.
  /// Using individual tweens is more efficient than tween the entire parent
  /// 从详细信息视图返回时应淡入的所有项目。
  /// 使用单个补间比使用整个父级补间更有效
  final _fadeAnims = <AnimationController>[];

  WonderData get currentWonder => _wonders[_wonderIndex];

  late final _VerticalSwipeController _swipeController = _VerticalSwipeController(this, _showDetailsPage);

  bool _isSelected(WonderType t) => t == currentWonder.type;

  @override
  void initState() {
    super.initState();
    // Create page controller,
    // allow 'infinite' scrolling by starting at a very high page, or remember the previous value
    // 创建页面控制器，
    // 通过从非常高的页面开始允许“无限”滚动，或者记住以前的值
    final initialPage = _numWonders * 9999;
    _pageController = PageController(viewportFraction: 1, initialPage: initialPage);
    _wonderIndex = initialPage % _numWonders;
  }

  void _handlePageChanged(value) {
    setState(() {
      _wonderIndex = value % _numWonders;
    });
    AppHaptics.lightImpact();
  }

  void _handleOpenMenuPressed() async {
    setState(() => _isMenuOpen = true);
    WonderType? pickedWonder = await appLogic.showFullscreenDialogRoute<WonderType>(
      context,
      HomeMenu(data: currentWonder),
      transparent: true,
    );
    setState(() => _isMenuOpen = false);
    if (pickedWonder != null) {
      _setPageIndex(_wonders.indexWhere((w) => w.type == pickedWonder));
    }
  }

  void _handleFadeAnimInit(AnimationController controller) {
    _fadeAnims.add(controller);
    controller.value = 1;
  }

  void _handlePageIndicatorDotPressed(int index) => _setPageIndex(index);

  void _setPageIndex(int index) {
    if (index == _wonderIndex) return;
    // To support infinite scrolling, we can't jump directly to the pressed index. Instead, make it relative to our current position.
    // 为了支持无限滚动，我们不能直接跳转到按下的索引。相反，使其相对于我们当前的位置。
    final pos = ((_pageController.page ?? 0) / _numWonders).floor() * _numWonders;
    _pageController.jumpToPage(pos + index);
  }

  void _showDetailsPage() async {
    _swipeOverride = _swipeController.swipeAmt.value;
    context.push(ScreenPaths.wonderDetails(currentWonder.type));
    await Future.delayed(100.ms);
    _swipeOverride = null;
    _fadeInOnNextBuild = true;
  }

  void _startDelayedFgFade() async {
    try {
      for (var a in _fadeAnims) {
        a.value = 0;
      }
      await Future.delayed(300.ms);
      for (var a in _fadeAnims) {
        a.forward();
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fadeInOnNextBuild == true) {
      _startDelayedFgFade();
      _fadeInOnNextBuild = false;
    }

    return _swipeController.wrapGestureDetector(Container(
      color: $styles.colors.black,
      child: Stack(
        children: [
          Stack(
            children: [
              /// Background
              /// 背景
              ..._buildBgAndClouds(),

              /// Wonders Illustrations (main content)
              /// 奇迹插图（主要内容）
              _buildMgPageView(),

              /// Foreground illustrations and gradients
              /// 前景插图和渐变
              _buildFgAndGradients(),

              /// Controls that float on top of the various illustrations
              /// 漂浮在各种插图之上的控件
              _buildFloatingUi(),
            ],
          ).animate().fadeIn(),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Widget _buildMgPageView() {
    return ExcludeSemantics(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _handlePageChanged,
        itemBuilder: (_, index) {
          final wonder = _wonders[index % _wonders.length];
          final wonderType = wonder.type;
          bool isShowing = _isSelected(wonderType);
          return _swipeController.buildListener(
            builder: (swipeAmt, _, child) {
              final config = WonderIllustrationConfig.mg(
                isShowing: isShowing,
                zoom: .05 * swipeAmt,
              );
              return WonderIllustration(wonderType, config: config);
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildBgAndClouds() {
    return [
      // Background
      ..._wonders.map((e) {
        final config = WonderIllustrationConfig.bg(isShowing: _isSelected(e.type));
        return WonderIllustration(e.type, config: config);
      }).toList(),
      // Clouds
      FractionallySizedBox(
        widthFactor: 1,
        heightFactor: .5,
        child: AnimatedClouds(wonderType: currentWonder.type, opacity: 1),
      )
    ];
  }

  Widget _buildFgAndGradients() {
    Widget buildSwipeableBgGradient(Color fgColor) {
      return _swipeController.buildListener(builder: (swipeAmt, isPointerDown, _) {
        return IgnorePointer(
          child: FractionallySizedBox(
            heightFactor: .6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fgColor.withOpacity(0),
                    fgColor.withOpacity(.5 + fgColor.opacity * .25 + (isPointerDown ? .05 : 0) + swipeAmt * .20),
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
        );
      });
    }

    final gradientColor = currentWonder.type.bgColor;
    return Stack(children: [
      /// Foreground gradient-1, gets darker when swiping up
      /// 前景渐变-1，向上滑动时变暗
      BottomCenter(
        child: buildSwipeableBgGradient(gradientColor.withOpacity(.65)),
      ),

      /// Foreground decorators
      /// 前景装饰器
      ..._wonders.map((e) {
        return _swipeController.buildListener(builder: (swipeAmt, _, child) {
          final config = WonderIllustrationConfig.fg(
            isShowing: _isSelected(e.type),
            zoom: .4 * (_swipeOverride ?? swipeAmt),
          );
          return Animate(
              effects: const [FadeEffect()],
              onPlay: _handleFadeAnimInit,
              child: IgnorePointer(child: WonderIllustration(e.type, config: config)));
        });
      }).toList(),

      /// Foreground gradient-2, gets darker when swiping up
      /// 前景渐变-2，向上滑动时变暗
      BottomCenter(
        child: buildSwipeableBgGradient(gradientColor),
      ),
    ]);
  }

  Widget _buildFloatingUi() {
    return Stack(children: [
      /// Floating controls / UI
      /// 浮动控件/用户界面
      AnimatedSwitcher(
        duration: $styles.times.fast,
        child: AnimatedOpacity(
          opacity: _isMenuOpen ? 0 : 1,
          duration: $styles.times.med,
          child: RepaintBoundary(
            child: OverflowBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity),
                  const Spacer(),

                  /// Title Content
                  /// 标题内容
                  LightText(
                    child: IgnorePointer(
                      ignoringSemantics: false,
                      child: Transform.translate(
                        offset: Offset(0, 30),
                        child: Column(
                          children: [
                            Semantics(
                              liveRegion: true,
                              button: true,
                              header: true,
                              onIncrease: () => _setPageIndex(_wonderIndex + 1),
                              onDecrease: () => _setPageIndex(_wonderIndex - 1),
                              onTap: () => _showDetailsPage(),
                              // Hide the title when the menu is open for visual polish
                              // 菜单打开时隐藏标题以提高视觉效果
                              child: WonderTitleText(currentWonder, enableShadows: true),
                            ),
                            Gap($styles.insets.md),
                            AppPageIndicator(
                              count: _numWonders,
                              controller: _pageController,
                              color: $styles.colors.white,
                              dotSize: 8,
                              onDotPressed: _handlePageIndicatorDotPressed,
                              semanticPageTitle: $strings.homeSemanticWonder,
                            ),
                            Gap($styles.insets.md),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Animated arrow and background
                  /// Wrap in a container that is full-width to make it easier to find for screen readers
                  /// 动画箭头和背景
                  /// 包装在全角容器中，以便屏幕阅读器更容易找到
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,

                    /// Lose state of child objects when index changes, this will re-run all the animated switcher and the arrow anim
                    /// 当索引更改时丢失子对象的状态，这将重新运行所有动画切换器和箭头动画
                    key: ValueKey(_wonderIndex),
                    child: Stack(
                      children: [
                        /// Expanding rounded rect that grows in height as user swipes up
                        /// 当用户向上滑动时，扩展的圆角矩形的高度会增加
                        Positioned.fill(
                            child: _swipeController.buildListener(
                          builder: (swipeAmt, _, child) {
                            double heightFactor = .5 + .5 * (1 + swipeAmt * 4);
                            return FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: heightFactor,
                              child: Opacity(opacity: swipeAmt * .5, child: child),
                            );
                          },
                          child: VtGradient(
                            [$styles.colors.white.withOpacity(0), $styles.colors.white.withOpacity(1)],
                            const [.3, 1],
                            borderRadius: BorderRadius.circular(99),
                          ),
                        )),

                        /// Arrow Btn that fades in and out
                        /// 淡入淡出的箭头 Btn
                        _AnimatedArrowButton(onTap: _showDetailsPage, semanticTitle: currentWonder.title),
                      ],
                    ),
                  ),
                  Gap($styles.insets.md),
                ],
              ),
            ),
          ),
        ),
      ),

      /// Menu Btn
      /// 菜单按钮
      TopLeft(
        child: AnimatedOpacity(
          duration: $styles.times.fast,
          opacity: _isMenuOpen ? 0 : 1,
          child: AppHeader(
            backIcon: AppIcons.menu,
            backBtnSemantics: $strings.homeSemanticOpenMain,
            onBack: _handleOpenMenuPressed,
            isTransparent: true,
          ),
        ),
      ),
    ]);
  }
}
