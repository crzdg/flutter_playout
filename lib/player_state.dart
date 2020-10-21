/// Communicates the current state of the player.
enum PlayerState {

  /// Player is stopped TODO: will be deprecated!
  STOPPED,

  /// Player is initialized
  INITIALIZED,

  /// Player is ready to play
  READY,

  /// Currently playing. The user can [pause] or [resume] the playback.
  PLAYING,

  /// Paused. The user can [resume] the playback without providing the URL.
  PAUSED,

  /// Created. state after object initialization (flutter and native side).
  CREATED,

  /// An error occured in the player.
  ERROR,

  /// Player is destroyed properly. A new player instance could be initialized
  COMPLETE

}
