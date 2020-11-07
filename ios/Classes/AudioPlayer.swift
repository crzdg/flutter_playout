//  AudioPlayer.swift
//  Runner
//
//  Created by Khuram Khalid on 27/09/2019.
//

import Foundation
import AVFoundation
import Flutter
import MediaPlayer

// Swift player implements the interface audio.dart
// The method handle, processes the methods invoked from audio.dart
// TODO: implement, changeMediaInfo, changeRadioURL
// changeMediaInfo: update the title and subtitle of the played media
// changeRadioURL: stop the player, change the radio url, start player
// TODO: refactor all other methods...

class AudioPlayer: NSObject, FlutterPlugin, FlutterStreamHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        print("Register flutter!")
        let player = AudioPlayer()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch _ { }
        let channel = FlutterMethodChannel(name: "tv.mta/NativeAudioChannel", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(player, channel: channel)
        setupEventChannel(messenger: registrar.messenger(), instance: player)
    }

    private static func setupEventChannel(messenger:FlutterBinaryMessenger, instance:AudioPlayer) {
        /* register for Flutter event channel */
        instance.eventChannel = FlutterEventChannel(name: "tv.mta/NativeAudioEventChannel",
                                                    binaryMessenger: messenger,
                                                    codec: FlutterJSONMethodCodec.sharedInstance())
        instance.eventChannel!.setStreamHandler(instance)
    }

    private func initPlayer() {
        print("init player ")
        _initPlayer()
        print("sink oninit")
        self.flutterEventSink?(["name":"onInit"])
    }

    private func _initPlayer() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            self.flutterEventSink?(["name":"onError", "error":"could not play"])
        }
    }

    private func changeMediaInfo(arguments: NSDictionary) {
        if let _title = arguments["title"] as? String {
            if let _subtitle = arguments["subtitle"] as? String {
                self.title = _title
                self.subtitle = _subtitle
                updateNowPlayingInfoPanel()
                self.flutterEventSink?(["name":"onChangeMediaInfo"])
                }
            }
    }

    private func play() {
        self._play()
        audioPlayer.play()
        self.flutterEventSink?(["name":"onStartPlaying"])
        updateInfoPanelOnPlay()

    }

    private func pause() {
        audioPlayer.pause()
        self.flutterEventSink?(["name":"onPausing"])
        self._setup()
        updateInfoPanelOnPause()
    }

    private func dispose() {
        teardown()
        self.flutterEventSink?(["name":"onComplete"])
        return;
    }

    private func _setup(){
        if let _url = URL(string: self.url) {
            let asset = AVAsset(url: _url)
            if (asset.isPlayable) {
                self.flutterEventSink?(["name":"onReady"])
            }
            else {
                self.flutterEventSink?(["name":"onError", "error":"asset not playable"])
            }
        }
    }

    private func setup(arguments: NSDictionary) {
        if let _url = arguments["url"] as? String {
            if let _title = arguments["title"] as? String {
                if let _subtitle = arguments["subtitle"] as? String {
                    self.title = _title
                    self.subtitle = _subtitle
                    self.url = _url
                    self._setup()
                    }
                }
            }
    }

    private func _play() {
        if let _url = URL(string: self.url) {
            let asset = AVAsset(url: _url)
                if (asset.isPlayable) {
                        audioPlayer = AVPlayer(url: _url)
                        let center = NotificationCenter.default
                        center.addObserver(self, selector: #selector(onComplete(_:)),
                                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                            object: self.audioPlayer.currentItem)
                        center.addObserver(self, selector:#selector(onAVPlayerNewErrorLogEntry(_:)),
                                            name: .AVPlayerItemNewErrorLogEntry,
                                            object: audioPlayer.currentItem)
                        center.addObserver(self, selector:#selector(onAVPlayerFailedToPlayToEndTime(_:)),
                                            name: .AVPlayerItemFailedToPlayToEndTime,
                                            object: audioPlayer.currentItem)
                        /* Add observer for AVPlayer status and AVPlayerItem status */
                        self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayer.status),
                                                        options: [.new, .initial], context: nil)
                        self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),
                                                        options:[.old, .new, .initial], context: nil)
                        self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                                                        options:[.old, .new, .initial], context: nil)
                        setupRemoteTransportControls();
                        setupNowPlayingInfoPanel()
                    }
                    audioPlayer.play()
                }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("init" == call.method) {
            initPlayer()
            result(true)
        }
        else if ("setup" == call.method) {
            if let arguments = call.arguments as? NSDictionary{
                setup(arguments: arguments)
                result(true)
            }
        }
        else if ("play" == call.method) {
            play()
            result(true)
        }
        else if ("pause" == call.method) {
            pause()
            result(true)
        }
        else if ("changeMediaInfo" == call.method) {
            if let arguments = call.arguments as? NSDictionary {
                changeMediaInfo(arguments: arguments)
                result(true)
            }
        }
        else if ("reset" == call.method) {
            reset()
            result(true)
        }
        else if ("dispose" == call.method) {
            dispose()
            result(true)
        }

        else { result(FlutterMethodNotImplemented) }
    }

    private var audioPlayer = AVPlayer()
    private var timeObserverToken:Any?

    private var remoteObserverInitialized = false;

    /* Flutter event streamer properties */
    private var eventChannel:FlutterEventChannel?
    private var flutterEventSink:FlutterEventSink?
    private var nowPlayingInfo = [String : Any]()
    private var mediaDuration = 0.0
    private var mediaURL = ""
    private var url:String = ""
    private var title:String = ""
    private var subtitle:String = ""

    @objc func onComplete(_ notification: Notification) {
        pause()
        self.flutterEventSink?(["name":"onComplete"])
        updateInfoPanelOnComplete()
    }

    /* Observe If AVPlayerItem.status Changed to Fail */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let newStatus: AVPlayerItem.Status
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
                self.flutterEventSink?(["name":"onError", "error":"unknown status"])
            }

            if newStatus == .failed {
                self.flutterEventSink?(["name":"onError", "error":(String(describing: self.audioPlayer.currentItem?.error))])
            }
        }

        else if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            guard let p = object as! AVPlayer? else {
                return
            }

            if #available(iOS 10.0, *) {
                switch (p.timeControlStatus) {
                case AVPlayerTimeControlStatus.paused:
                    self.flutterEventSink?(["name":"onPause"])
                    break
                case AVPlayerTimeControlStatus.playing:
                    self.flutterEventSink?(["name":"onPlaying"])
                    break
                case .waitingToPlayAtSpecifiedRate: break
                @unknown default:
                    break
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    @objc func onAVPlayerNewErrorLogEntry(_ notification: Notification) {
        guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
            self.flutterEventSink?(["name":"onError", "error":"unknown error"])
            return
        }
        guard let error: AVPlayerItemErrorLog = playerItem.errorLog() else {
            self.flutterEventSink?(["name":"onError", "error":"unknown error"])
            return
        }
        guard var errorMessage = error.extendedLogData() else {
            self.flutterEventSink?(["name":"onError", "error":"unknown error"])
            return
        }
        errorMessage.removeLast()
        self.flutterEventSink?(["name":"onError", "error":String(data: errorMessage, encoding: .utf8)])
    }

    @objc func onAVPlayerFailedToPlayToEndTime(_ notification: Notification) {
        guard let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] else {
            self.flutterEventSink?(["name":"onError", "error":"unknown error"])
            return
        }
        self.flutterEventSink?(["name":"onError", "error":"failed to end"])
    }

    private func setupRemoteTransportControls() {
        if (remoteObserverInitialized == false) {
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.isEnabled = true
            commandCenter.pauseCommand.isEnabled = true
            // Add handler for Play Command
            //commandCenter.playCommand.addTarget(self, action: #selector(self.play(_:)))
            //commandCenter.pauseCommand.addTarget(self, action: #selector(self.play(_:)))
            commandCenter.playCommand.addTarget { event in
                if self.audioPlayer.rate == 0.0 {
                    self.play()
                    print("play button")
                    return .success
                }
                return .commandFailed
            }

            // Add handler for Pause Command
            commandCenter.pauseCommand.addTarget { event in
                if self.audioPlayer.rate == 1.0 {
                    self.pause()
                    print("pause button")
                    return .success
                }
                return .commandFailed
            }
            remoteObserverInitialized = true
        }
    }

    private func setupNowPlayingInfoPanel() {
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.subtitle
        if #available(iOS 10.0, *) {
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.currentItem?.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0 // will be set to 1 by onTime callback
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingInfoPanel() {
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.subtitle
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func reset() {
        self.flutterEventSink?(["name":"onReset"])
        audioPlayer.pause()
        _setup()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func teardown() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        if let timeObserver = timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserver)
            timeObserverToken = nil
        }
        /* stop playback */
        self.audioPlayer.pause()
        /* reset state */
        self.mediaURL = ""
        self.mediaDuration = 0.0
        NotificationCenter.default.removeObserver(self)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch _ { }
    }

    private func onTimeInterval(time:CMTime) {
        self.flutterEventSink?(["name":"onTime", "time":self.audioPlayer.currentTime().seconds])
        updateInfoPanelOnTime()
        onDurationChange()
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        flutterEventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flutterEventSink = nil
        return nil
    }

    private func updateInfoPanelOnPause() {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.audioPlayer.currentTime()))
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateInfoPanelOnPlay() {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(((self.audioPlayer.currentTime())))
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }

    private func updateInfoPanelOnComplete() {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateInfoPanelOnTime() {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.audioPlayer.currentTime()))
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }

    private func onDurationChange() {
        guard let item = self.audioPlayer.currentItem else { return }
        let newDuration = item.duration.seconds * 1000
        if (newDuration.isNaN) {
            self.mediaDuration = newDuration
            self.flutterEventSink?(["name":"onDuration", "duration":-1])
        } else if (newDuration != mediaDuration) {
            self.mediaDuration = newDuration
            self.flutterEventSink?(["name":"onDuration", "duration":self.mediaDuration])
        }
    }
}
