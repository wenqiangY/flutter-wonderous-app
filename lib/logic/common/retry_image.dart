import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// An image provider that retries if loading the bytes failed.
///
/// Useful for network image requests that may transiently fail.
/// 如果加载字节失败，图像提供程序会重试。
///
/// 对于可能暂时失败的网络图像请求很有用。
@immutable
class RetryImage extends ImageProvider<Object> {
  /// Creates an object that uses [imageProvider] to fetch and decode an image,
  /// and retries if fetching fails.
  /// 创建一个使用 [imageProvider] 获取和解码图像的对象，
  /// 并在获取失败时重试。
  const RetryImage(this.imageProvider, {this.scale = 1.0, this.maxRetries = 4});

  /// A wrapped image provider to use.
  /// 要使用的包装图像提供程序。
  final ImageProvider imageProvider;

  /// The maximum number of times to retry.
  /// 重试的最大次数。
  final int maxRetries;

  /// The scale to place in the [ImageInfo] object of the image.
  ///
  /// Must be the same as the scale argument provided to [imageProvider], if
  /// any.
  /// 要放置在图像的 [ImageInfo] 对象中的比例。
  ///
  /// 必须与提供给 [imageProvider] 的比例参数相同，如果
  /// 任何。
  final double scale;

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    Completer<Object>? completer;
    // If the imageProvider.obtainKey future is synchronous, then we will be able to fill in result with
    // a value before completer is initialized below.
    // 如果 imageProvider.obtainKey future 是同步的，那么我们将能够用以下内容填充结果
    // 下面初始化完成者之前的值。
    SynchronousFuture<Object>? result;
    imageProvider.obtainKey(configuration).then((Object key) {
      if (completer == null) {
        // This future has completed synchronously (completer was never assigned),
        // so we can directly create the synchronous result to return.
        // 这个 future 已同步完成（从未分配完成者），
        // 所以我们可以直接创建同步结果返回。
        result = SynchronousFuture<Object>(key);
      } else {
        // This future did not synchronously complete.
        // 这个未来并没有同步完成。
        completer.complete(key);
      }
    });
    if (result != null) {
      return result!;
    }
    // If the code reaches here, it means the imageProvider.obtainKey was not
    // completed sync, so we initialize the completer for completion later.
    // 如果代码到达这里，则意味着 imageProvider.obtainKey 没有
    // 已完成同步，因此我们初始化完成器以便稍后完成。
    completer = Completer<Object>();
    return completer.future;
  }

  ImageStreamCompleter _commonLoad(ImageStreamCompleter Function() loader) {
    final _DelegatingImageStreamCompleter completer = _DelegatingImageStreamCompleter();
    ImageStreamCompleter completerToWrap = loader();
    late ImageStreamListener listener;

    Duration duration = const Duration(milliseconds: 250);
    int count = 1;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        completer.addImage(image);
      },
      onChunk: completer._reportChunkEvent,
      onError: (Object exception, StackTrace? stackTrace) {
        completerToWrap.removeListener(listener);
        if (count > maxRetries) {
          completer.reportError(exception: exception, stack: stackTrace);
          return;
        }
        Future<void>.delayed(duration).then((void v) {
          duration *= 2;
          completerToWrap = loader();
          count += 1;
          completerToWrap.addListener(listener);
        });
      },
    );
    completerToWrap.addListener(listener);

    completer.addOnLastListenerRemovedCallback(() {
      completerToWrap.removeListener(listener);
    });

    return completer;
  }

  @override
  // ignore: deprecated_member_use
  // 忽略：deprecated_member_use
  ImageStreamCompleter load(Object key, DecoderCallback decode) {
    // ignore: deprecated_member_use
    // 忽略：deprecated_member_use
    return _commonLoad(() => imageProvider.load(key, decode));
  }

  @override
  ImageStreamCompleter loadBuffer(Object key, DecoderBufferCallback decode) {
    return _commonLoad(() => imageProvider.loadBuffer(key, decode));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RetryImage && other.imageProvider == other.imageProvider && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(imageProvider, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RetryImage')}(imageProvider: $imageProvider, maxRetries: $maxRetries, scale: $scale)';
}

class _DelegatingImageStreamCompleter extends ImageStreamCompleter {
  void addImage(ImageInfo info) {
    setImage(info);
  }

  void _reportChunkEvent(ImageChunkEvent event) {
    reportImageChunkEvent(event);
  }
}
