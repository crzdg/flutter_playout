package tv.mta.flutter_playout;

public enum PlayerState {
    CREATED,
    INITIALIZED,
    READY,
    PLAYING,
    PAUSED,
    IDLE,
    BUFFERING,
    ERROR,
    COMPLETE;

    private PlayerState() {
    }
}