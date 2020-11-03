package tv.mta.flutter_playout;

public enum PlayerState {
    CREATED,
    INITIALIZED,
    IDLE,
    ERROR,
    PREPARED,
    STOPPED,
    STARTED,
    PREPARING;

    private PlayerState() {
    }
}