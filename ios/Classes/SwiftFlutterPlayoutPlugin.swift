import Flutter
import UIKit

public class SwiftFlutterPlayoutPlugin: NSObject, FlutterPlugin {
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    
    /* register audio player */
    AudioPlayer.register(with: registrar)

    // TODO: video is not needed anymore
    /* register video player */
    VideoPlayerFactory.register(with: registrar)
  }
}
