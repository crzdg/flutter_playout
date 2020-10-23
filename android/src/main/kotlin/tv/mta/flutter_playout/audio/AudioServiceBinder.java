package tv.mta.flutter_playout.audio;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import java.io.IOException;

import tv.mta.flutter_playout.FlutterAVPlayer;
import tv.mta.flutter_playout.PlayerNotificationUtil;
import tv.mta.flutter_playout.PlayerState;
import tv.mta.flutter_playout.R;

public class AudioServiceBinder
        extends Binder
        implements FlutterAVPlayer, MediaPlayer.OnPreparedListener,
        MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

    private static final String TAG = "AudioServiceBinder";

    /**
     * The notification channel id we'll send notifications too
     */
    private static final String mNotificationChannelId = "NotificationBarController";
    /**
     * Playback Rate for the MediaPlayer is always 1.0.
     */
    private static final float PLAYBACK_RATE = 1.0f;
    /**
     * The notification id.
     */
    private static final int NOTIFICATION_ID = 0;
    static AudioServiceBinder service;
    // This is the message signal that inform audio progress updater to update audio progress.
    final int UPDATE_PLAYER_STATE_TO_COMPLETE = 1;
    final int UPDATE_PLAYER_STATE_TO_ERROR = 2;
    final int UPDATE_PLAYER_STATE_TO_INITIALIZED = 3;
    final int UPDATE_PLAYER_STATE_TO_READY = 4;
    final int UPDATE_PLAYER_STATE_TO_START_PLAYING = 5;
    final int UPDATE_PLAYER_STATE_TO_PLAYING = 6;
    final int UPDATE_PLAYER_STATE_TO_PAUSING = 7;
    private PlayerState playerState = PlayerState.CREATED;


    /**
     * Whether the {@link MediaPlayer} broadcasted an error.
     */
    private boolean mReceivedError;

    private String audioFileUrl = "";

    private String title = "";

    private String subtitle = "";

    private MediaPlayer audioPlayer = null;

    // This Handler object is a reference to the caller activity's Handler.
    // In the caller activity's handler, it will update the audio play progress.
    private Handler audioProgressUpdateHandler;

    /**
     * The underlying {@link MediaSessionCompat}.
     */
    private MediaSessionCompat mMediaSessionCompat;

    private Context context;

    private Activity activity;

    MediaPlayer getAudioPlayer() {
        return audioPlayer;
    }

    String getAudioFileUrl() {
        return audioFileUrl;
    }

    void setAudioFileUrl(String audioFileUrl) {
        this.audioFileUrl = audioFileUrl;
    }

    void setTitle(String title) {
        this.title = title;
    }

    void setSubtitle(String subtitle) {
        this.subtitle = subtitle;
    }

    void setAudioProgressUpdateHandler(Handler audioProgressUpdateHandler) {
        this.audioProgressUpdateHandler = audioProgressUpdateHandler;
    }

    PlayerState getPlayerState() {return playerState;}

    private Context getContext() {
        return context;
    }

    void setContext(Context context) {
        this.context = context;
    }

    void setActivity(Activity activity) {
        this.activity = activity;
    }

    private void setAudioMetadata() {
        MediaMetadataCompat metadata = new MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, subtitle)
                .build();

        mMediaSessionCompat.setMetadata(metadata);
    }

    private void updateAudioProgressUpdateHandler(int what){
        Message updateAudioProgressMsg = new Message();
        updateAudioProgressMsg.what = what;
        audioProgressUpdateHandler.sendMessage(updateAudioProgressMsg);
    }

    void startAudio() {
        Log.d("startAudio", "startAudio");
        if (audioPlayer != null && audioPlayer.isPlaying() == false) {
            updateAudioProgressUpdateHandler(UPDATE_PLAYER_STATE_TO_START_PLAYING);
            audioPlayer.prepareAsync();
            updatePlayerState(PlayerState.PREPARING);
        }
        service = this;
    }

    void pauseAudio() {
        Log.d("ANDROID", "pauseAudio");
        if (audioPlayer != null) {
            if (audioPlayer.isPlaying()) {
                Log.d("ANDROID", "isplaying");
                //audioPlayer.pause();
                audioPlayer.stop();
                updatePlayerState(PlayerState.STOPPED);
            }
            updateAudioProgressUpdateHandler(UPDATE_PLAYER_STATE_TO_PAUSING);
            audioPlayer.reset();
            makeAudioPlayerReady();
        }
    }

    void cleanPlayerNotification() {
        NotificationManager notificationManager = (NotificationManager)
                getContext().getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager != null) {
            notificationManager.cancel(NOTIFICATION_ID);
        }
    }

    void updateRadioInformations(String title, String subtitle) {
        setTitle(title);
        setSubtitle(subtitle);
        setAudioMetadata();
        updatePlayerState(this.playerState);
    }

    void setupAudioPlayer(String url, String title, String subtitle) {
        setAudioFileUrl(url);
        setTitle(title);
        setSubtitle(subtitle);
        makeAudioPlayerReady();
    }

    private void makeAudioPlayerReady() {
        try {
            if (!TextUtils.isEmpty(getAudioFileUrl())) {
                audioPlayer.setDataSource(getAudioFileUrl());
                updatePlayerState(PlayerState.INITIALIZED);
            }

        } catch (IOException e){
            updatePlayerState(PlayerState.ERROR);
        }
        updateAudioProgressUpdateHandler(UPDATE_PLAYER_STATE_TO_READY);
    }

    void initAudioPlayer() {
        try {
            if (audioPlayer == null) {
                audioPlayer = new MediaPlayer();
                audioPlayer.setOnPreparedListener(this);
                audioPlayer.setOnCompletionListener(this);
                audioPlayer.setOnErrorListener(this);
                updatePlayerState(PlayerState.IDLE);
                updateAudioProgressUpdateHandler(UPDATE_PLAYER_STATE_TO_INITIALIZED);
            }

            else {
                updatePlayerState(PlayerState.ERROR);
                //audioPlayer.start();
            }

        } catch (Exception ex) {
            mReceivedError = true;
        }
    }

    @Override
    public void onDestroy() {
        Log.d("ANDROID", "onDestroy");
        try {
            cleanPlayerNotification();
            if (audioPlayer != null) {
                if (audioPlayer.isPlaying()) {
                    audioPlayer.stop();
                }
                audioPlayer.reset();
                audioPlayer.release();
                audioPlayer = null;
            }
        } catch (Exception e) { /* ignore */ }
    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        updatePlayerState(PlayerState.PREPARED);
        ComponentName receiver = new ComponentName(context.getPackageName(),
                RemoteReceiver.class.getName());
        /* Create a new MediaSession */
        mMediaSessionCompat = new MediaSessionCompat(context,
                AudioServiceBinder.class.getSimpleName(), receiver, null);
        mMediaSessionCompat.setFlags(MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                | MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS);
        mMediaSessionCompat.setCallback(new MediaSessionCallback(audioPlayer));
        mMediaSessionCompat.setActive(true);
        audioPlayer.start();
        setAudioMetadata();
        updatePlayerState(PlayerState.STARTED);
        updateAudioProgressUpdateHandler(UPDATE_PLAYER_STATE_TO_PLAYING);
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        Log.d("ANDROID", "on completion");
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {
        Log.d("ANDROID", "on error");
        //updatePlayerState(PlayerState.ERROR);

        // Create update audio player state message.
        Message updateAudioPlayerStateMessage = new Message();

        updateAudioPlayerStateMessage.what = UPDATE_PLAYER_STATE_TO_ERROR;

        Log.e("AudioServiceBinder", "onPlayerError: [what=" + what + "] [extra=" + extra + "]", null);
        String errorMessage = "";
        switch (what) {
            case MediaPlayer.MEDIA_ERROR_IO:
                errorMessage = "MEDIA_ERROR_IO: File or network related operation error";
                break;
            case MediaPlayer.MEDIA_ERROR_MALFORMED:
                errorMessage = "MEDIA_ERROR_MALFORMED: Bitstream is not conforming to the related" +
                        " coding standard or file spec";
                break;
            case MediaPlayer.MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:
                errorMessage = "MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:  The video is str" +
                        "eamed and its container is not valid for progressive playback i.e the vi" +
                        "deo's index (e.g moov atom) is not at the start of the file";
                break;
            case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                errorMessage = "MEDIA_ERROR_SERVER_DIED: Media server died";
                break;
            case MediaPlayer.MEDIA_ERROR_TIMED_OUT:
                errorMessage = "MEDIA_ERROR_TIMED_OUT: Some operation takes too long to complete," +
                        " usually more than 3-5 seconds";
                break;
            case MediaPlayer.MEDIA_ERROR_UNKNOWN:
                errorMessage = "MEDIA_ERROR_UNKNOWN: Unspecified media player error";
                break;
            case MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                errorMessage = "MEDIA_ERROR_UNSUPPORTED: Bitstream is conforming to the related c" +
                        "oding standard or file spec, but the media framework does not support th" +
                        "e feature";
                break;
            default:
                errorMessage = "MEDIA_ERROR_UNKNOWN: Unspecified media player error";
                break;
        }

        Log.e("AudioServiceBinder", errorMessage, null);


        updateAudioPlayerStateMessage.obj = errorMessage;

        // Send the message to caller activity's update audio Handler object.
        audioProgressUpdateHandler.sendMessage(updateAudioPlayerStateMessage);

        return false;
    }

    private PlaybackStateCompat.Builder getPlaybackStateBuilder() {

        PlaybackStateCompat playbackState = mMediaSessionCompat.getController().getPlaybackState();

        return playbackState == null
                ? new PlaybackStateCompat.Builder()
                : new PlaybackStateCompat.Builder(playbackState);
    }

    private void updatePlayerState(PlayerState playerState) {
        this.playerState = playerState;
        if (mMediaSessionCompat == null) return;
        PlaybackStateCompat.Builder newPlaybackState = getPlaybackStateBuilder();
        long capabilities = getCapabilities();
        newPlaybackState.setActions(capabilities);
        int playbackStateCompat = PlaybackStateCompat.STATE_NONE;

        switch (this.playerState) {
            case STARTED:
                playbackStateCompat = PlaybackStateCompat.STATE_PLAYING;
                break;
            case PREPARED:
                playbackStateCompat = PlaybackStateCompat.STATE_BUFFERING;
                break;
            case PREPARING:
                playbackStateCompat = PlaybackStateCompat.STATE_BUFFERING;
                break;
            case STOPPED:
                playbackStateCompat = PlaybackStateCompat.STATE_BUFFERING;
                break;
            case INITIALIZED:
                playbackStateCompat = PlaybackStateCompat.STATE_PAUSED;
                break;
            case ERROR:
                playbackStateCompat = PlaybackStateCompat.STATE_ERROR;
                break;
            case IDLE:
                if (mReceivedError) {
                    playbackStateCompat = PlaybackStateCompat.STATE_ERROR;
                } else {
                    playbackStateCompat = PlaybackStateCompat.STATE_NONE;
                }
                break;
        }

        if (audioPlayer != null) {
            newPlaybackState.setState(playbackStateCompat, 0, PLAYBACK_RATE);
        }

        mMediaSessionCompat.setPlaybackState(newPlaybackState.build());
        updateNotification(capabilities);
    }

    private @PlaybackStateCompat.Actions
    long getCapabilities() {
        long capabilities = 0;

        switch (this.playerState) {
            case IDLE:
                break;
            case INITIALIZED:
                capabilities |= PlaybackStateCompat.ACTION_PLAY;
                break;
            case PREPARED:
                break;
            case STARTED:
                capabilities |= PlaybackStateCompat.ACTION_PAUSE;
                break;
            case STOPPED:
                capabilities |= PlaybackStateCompat.ACTION_PLAY
                        | PlaybackStateCompat.ACTION_STOP;
                break;
            case PREPARING:
                capabilities = 0;
                break;
        }
        return capabilities;
    }

    private void updateNotification(long capabilities) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            createNotificationChannel();
        }

        NotificationCompat.Builder notificationBuilder = PlayerNotificationUtil.from(
                activity, context, mMediaSessionCompat, mNotificationChannelId);

        notificationBuilder.setPriority(Notification.PRIORITY_MAX).setWhen(0);

        if ((capabilities & PlaybackStateCompat.ACTION_PAUSE) != 0) {
            notificationBuilder.addAction(R.drawable.ic_pause, "Pause",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PAUSE));
        }

        if ((capabilities & PlaybackStateCompat.ACTION_PLAY) != 0) {
            notificationBuilder.addAction(R.drawable.ic_play, "Play",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY));
        }

        if (capabilities == 0) {
            notificationBuilder.setContentText("Loading ... ");
        }

        NotificationManager notificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager != null) {
            notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private void createNotificationChannel() {

        NotificationManager notificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        CharSequence channelNameDisplayedToUser = "Notification Bar Controls";

        int importance = NotificationManager.IMPORTANCE_LOW;

        NotificationChannel newChannel = new NotificationChannel(
                mNotificationChannelId, channelNameDisplayedToUser, importance);

        newChannel.setDescription("All notifications");

        newChannel.setShowBadge(false);

        newChannel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);

        if (notificationManager != null) {

            notificationManager.createNotificationChannel(newChannel);
        }
    }

    /**
     * A {@link android.support.v4.media.session.MediaSessionCompat.Callback} implementation for MediaPlayer.
     */
    private final class MediaSessionCallback extends MediaSessionCompat.Callback {

        MediaSessionCallback(MediaPlayer player) {
            audioPlayer = player;
        }

        @Override
        public void onPause() {
            Log.d("MediaSessionCallback", "onPause");
            //pauseAudio();
        }

        @Override
        public void onPlay() {
            Log.d("MediaSessionCallback", "onPlay");
            //startAudio();
        }

        @Override
        public void onStop() {
            Log.d("MediaSessionCallback", "onStop");
            //pauseAudio();
        }
    }
}