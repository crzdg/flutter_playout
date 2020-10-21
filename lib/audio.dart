import 'package:flutter/services.dart';
import 'package:flutter_playout/channel_observer.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/player_state_oberserver.dart';

/// See [play] method as well as example app on how to use.
class Audio with ChannelObserver {
  static const MethodChannel _audioChannel =
      MethodChannel('tv.mta/NativeAudioChannel');

  Audio._(){
   this._state = PlayerState.CREATED;
  }

  List<PlayerStateObserver> _playerStateObservers = new List();
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
  Duration _position;
  bool _isLiveStream;

  void registerPlayerStateObserver(PlayerStateObserver observer){
    _playerStateObservers.add(observer);
    return;
  }

  void informPlayerStateObservers(String command){
    _playerStateObservers.forEach(
            (PlayerStateObserver observer) => observer.processEvent(command));
  }

  PlayerState getPlayerState() {
    return _state;
  }

  Future<void> initRadioPlayer() async {
    return _audioChannel.invokeMethod("initRadioPlayer");
  }

  @override
  void onError(String error) {
    _state = PlayerState.ERROR;
    informPlayerStateObservers("onError");
  }

  @override
  void onInitRadioPlayer() {
    _state = PlayerState.INITIALIZED;
    informPlayerStateObservers("onInitialized");
    return;
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

  @override
  void onSetupRadio() {
    _state = PlayerState.READY;
    informPlayerStateObservers("onReady");
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

  @override
  void onChangeMediaInfo() {
    informPlayerStateObservers("onChangeMediaInfo");
  }

  Future<void> changeRadioURL(String url) async {
    this._url = url;
    return _audioChannel.invokeMethod("changeRadioURL", <String, dynamic>{
        "url": url,
      });
  }

  @override
  void onChangeRadioURL() {
    informPlayerStateObservers("onChangeRadioURL");
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

  @override
  void onPlay(){
    this._state = PlayerState.PLAYING;
    informPlayerStateObservers("onPlaying");
  }

  Future<void> pause() async {
    return _audioChannel.invokeMethod("pause");
  }

  @override
  void onPause(){
    this._state = PlayerState.PAUSED;
    informPlayerStateObservers("onPaused");
  }

  Future<void> stop() async {
    return _audioChannel.invokeListMethod("stop");
  }

  @override
  void onStop(){
    this._state = PlayerState.STOPPED;
    informPlayerStateObservers("onStopped");
  }

  Future<void> reset() async {
    return _audioChannel.invokeMethod("reset");
  }

  @override
  void onReset(){
    this._state = PlayerState.INITIALIZED;
    informPlayerStateObservers("onReset");
  }

  Future<void> dispose() async {
    return _audioChannel.invokeMethod("dispose");
  }

  @override
  void onDispose(){
    _instance = null;
    this._state = PlayerState.COMPLETE;
    informPlayerStateObservers("onDispose");
  }

}
