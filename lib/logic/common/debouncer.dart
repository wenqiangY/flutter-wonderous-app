import 'dart:async';

import 'package:flutter/material.dart';

/// 防抖
class Debouncer {
  Debouncer(this.interval);
  final Duration interval;

  VoidCallback? _action;
  Timer? _timer;

  void call(VoidCallback action) {
    // Let the latest action override whatever was there before
    // 让最新的操作覆盖之前的操作
    _action = action;
    // Always cancel and restart the timer
    // 始终取消并重新启动计时器
    _timer?.cancel();
    _timer = Timer(interval, _callAction);
  }

  void _callAction() {
    // If we have an action queued up, complete it.
    // 如果我们有一个操作正在排队，请完成它。
    _action?.call(); 
    _timer = null;
  }

  void reset() {
    _action = null;
    _timer = null;
  }
}
