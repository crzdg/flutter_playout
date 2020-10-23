/// Communicates the current state of the player.
enum PlayerState {

  /// Player is stopped TODO: will be deprecated!
  CREATED,

  /// Player is initialized
  INITIALIZED,

  /// Currently playing. The user can [pause] or [resume] the playback.
  READY,

  /// Paused. The user can [resume] the playback without providing the URL.
  START_PLAYING,

  /// Created. state after object initialization (flutter and native side).
  PLAYING,

  /// An error occured in the player.
  PAUSING,

  /// Player is destroyed properly. A new player instance could be initialized
  COMPLETE,

  ERROR

}
