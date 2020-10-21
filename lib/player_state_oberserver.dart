


mixin PlayerStateObserver {

  void onCreated() {}

  void onReady() {}

  void onInitialized() {}

  void onPlaying() {}

  void onPaused() {}

  void onStopped() {}

  void onError() {}

  void onComplete() {}

  void processEvent(String event) {
    switch (event) {
      case "onCreated":
        onCreated();
        break;
      case "onReady":
        onReady();
        break;
      case "onInitialized":
        onInitialized();
        break;
      case "onPlaying":
        onPlaying();
        break;
      case "onPaused":
        onPaused();
        break;
      case "onStopped":
        onStopped();
        break;
      case "onError":
        onError();
        break;
      case "onComplete":
        onComplete();
        break;
      default:
        break;
      }
    }
}