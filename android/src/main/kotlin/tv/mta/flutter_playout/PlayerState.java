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
    PREPARED,
    STOPPED,
    STARTED,
    PREPARING,
    COMPLETE;

    private PlayerState() {
    }
}