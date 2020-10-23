import 'package:flutter/services.dart';
import 'package:flutter_playout/channel_observer.dart';
import 'package:flutter_playout/player_state.dart';

/// See [play] method as well as example app on how to use.
class Audio with ChannelObserver {
  static const MethodChannel _audioChannel =
      MethodChannel('tv.mta/NativeAudioChannel');

  Audio._(){
   this._state = PlayerState.CREATED;
   listenForAudioPlayerEvents();
  }

  static Audio _instance;
  static Audio instance() {
    if (_instance == null) {
      _instance = Audio._();
    }
    return _instance;
  }

  PlayerState _state;
  String _url;
  String _title;
  String _subtitle;

  PlayerState getPlayerState() {
    return _state;
  }

  Future<void> init() async {
    return _audioChannel.invokeMethod("init");
  }

  Future<void> setup(String url, String title,
      String subtitle) async {
    this._url = url;
    this._title = title;
    this._subtitle = subtitle;
    return _audioChannel.invokeMethod("setup", <String, dynamic>{
      "url": url,
      "title": title,
      "subtitle": subtitle
    });
  }

  Future<void> changeMediaInfo(String title, String subtitle) async {
    this._title = title;
    this._subtitle = subtitle;
    return _audioChannel.invokeMethod("changeMediaInfo", <String, dynamic>{
      "title": title,
      "subtitle": subtitle
    });
  }

  Future<void> play() async {
        return _audioChannel.invokeMethod("play");
    }

  Future<void> pause() async {
    return _audioChannel.invokeMethod("pause");
  }

  Future<void> reset() async {
    return _audioChannel.invokeMethod("reset");
  }

  Future<void> dispose() async {
    return _audioChannel.invokeMethod("dispose");
  }


  @override
  void onReset(){
    this._state = PlayerState.INITIALIZED;
  }

  @override
  void onError(String error) {
    _state = PlayerState.ERROR;
  }

  @override
  void onInit() {
    _state = PlayerState.INITIALIZED;
    return;
  }

  @override
  void onDispose(){
    _instance = null;
    this._state = PlayerState.COMPLETE;
  }

  @override
  void onReady() {
    _state = PlayerState.READY;
    return;
  }

  @override
  void onStartPlaying() {
    _state = PlayerState.START_PLAYING;
    return;
  }

  @override
  void onPlaying() {
    _state = PlayerState.PLAYING;
    return;
  }

  @override
  void onPausing() {
    _state = PlayerState.PAUSING;
    return;
  }

  @override
  void onComplete() {
    _state = PlayerState.COMPLETE;
    return;
  }


}
