import 'dart:async';

import 'package:flutter/services.dart';

/// Use with Video or Audio widget to get player notifications such as
/// [onPlay], [onPause] etc. See example on how to use.
mixin ChannelObserver {
  Future<void> listenForAudioPlayerEvents() async {
    EventChannel eventChannel =
    EventChannel("tv.mta/NativeAudioEventChannel", JSONMethodCodec());
    eventChannel.receiveBroadcastStream().listen(_processEvent);
  }

  void onInit() {/* user implementation */}

  void onReady()  { /* user implementation */ }

  void onStartPlaying() { /* user implementation */ }

  void onPlaying() {/* user implementation */}

  void onPausing() {/* user implementation */}

  void onReset() {/* user implementation */}

  void onDispose() {/* user implementation */}

  void onComplete() {/* user implementation */}

  void onError(String error) {/* user implementation */}


  /// Override this method to get notifications when a seek operation has
  /// finished. This will occur when user finishes scrubbing media.
  /// [position] is position in seconds before seek started.
  /// [offset] is seconds after seek processed.
  /// void onSeek(int position, double offset) {/* user implementation */}

  /// Override this method to get notifications when media duration is
  /// set or changed.
  /// [duration] is in milliseconds. Returns -1 for live stream
  ///
  /// TODO: Maybe not needed
  // void onDuration(int duration) {/* user implementation */}

  // void onMediaSet() {/* user implementation */}

  void _processEvent(dynamic event) async {
    String eventName = event["name"];

    switch (eventName) {
      case "onInit":
        onInit();
        break;
      case "onReady":
        onReady();
        break;
      case "onStartPlaying":
        onStartPlaying();
        break;
      case "onPlaying":
        onPlaying();
        break;
      case "onPausing":
        onPausing();
        break;
      case "onComplete":
        onComplete();
        break;
      case "onReset":
        onReset();
        break;
      case "onDispose":
        onDispose();
        break;
      case "onError":
        onError(event["error"]);
        break;
      default:
        break;
    }
  }
}

