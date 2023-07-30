import 'dart:async';

import 'package:flutter/material.dart';

/// 节流
class Throttler {
  Throttler(this.interval);
  final Duration interval;

  VoidCallback? _action;
  Timer? _timer;

  void call(VoidCallback action, {bool immediateCall = true}) {
    // Let the latest action override whatever was there before
    // 让最新的操作覆盖之前的操作
    _action = action;
    // If no timer is running, we want to start one
    // 如果没有计时器在运行，我们想启动一个
    if (_timer == null) {
      //  If immediateCall is true, we handle the action now
      //  如果immediateCall为真，我们现在处理该操作
      if (immediateCall) {
        _callAction();
      }
      // Start a timer that will temporarily throttle subsequent calls, and eventually make a call to whatever _action is (if anything)
      // 启动一个计时器，该计时器将暂时限制后续调用，并最终调用任何 _action （如果有的话）
      _timer = Timer(interval, _callAction);
    }
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
