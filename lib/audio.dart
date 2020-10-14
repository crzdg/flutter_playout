import 'package:flutter/services.dart';

/// See [play] method as well as example app on how to use.
class Audio {
  static const MethodChannel _audioChannel =
      MethodChannel('tv.mta/NativeAudioChannel');

  Audio._();

  static Audio _instance;
  static Audio instance() {
    if (_instance == null) {
      _instance = Audio._();
    }
    return _instance;
  }

  String _url;
  String _title;
  String _subtitle;
  Duration _position;
  bool _isLiveStream;

  Future<void> initRadioPlayer() async {
    return _audioChannel.invokeMethod("initRadioPlayer");
  }

  Future<void> setUpRadio(String url, String title,
      String subtitle, Duration position) async {
    this._url = url;
    this._title = title;
    this._subtitle = subtitle;
    this._position = position;
    return _audioChannel.invokeMethod("setUpRadio", <String, dynamic>{
      "url": url,
      "title": title,
      "subtitle": subtitle,
      "position": position.inMilliseconds
    });
  }

  /// Change Media info of the player. Used to update title and subtitle.
  Future<void> changeMediaInfo(String title, String subtitle) async {
    this._title = title;
    this._subtitle = subtitle;
    return _audioChannel.invokeMethod("changeMediaInfo", <String, dynamic>{
      "title": title,
      "subtitle": subtitle
    });
  }

  /// Change Radio URL
  Future<void> changeRadioURL(String url) async {
    this._url = url;
    return _audioChannel.invokeMethod("changeRadioURL", <String, dynamic>{
        "url": url,
      });
  }


  /// Plays given [url] with native player. The [title] and [subtitle]
  /// are used for lock screen info panel on both iOS & Android. Optionally pass
  /// in current [position] to start playback from that point. The
  /// [isLiveStream] flag is only used on iOS to change the scrub-bar look
  /// on lock screen info panel. It has no affect on the actual functionality
  /// of the plugin. Defaults to false.
  Future<void> play() async {
        return _audioChannel.invokeMethod("play");
    }

  Future<void> pause() async {
    return _audioChannel.invokeMethod("pause");
  }

  Future<void> stop() async {
    return _audioChannel.invokeListMethod("stop");
  }

  Future<void> reset() async {
    return _audioChannel.invokeMethod("reset");
  }

  ///Future<void> seekTo(double seconds) async {
  ///  return _audioChannel.invokeMethod("seekTo", <String, dynamic>{
  ///    "second": seconds,
  ///  });
  ///}

  Future<void> dispose() async {
    _instance = null;
    await _audioChannel.invokeMethod("dispose");
  }
}
