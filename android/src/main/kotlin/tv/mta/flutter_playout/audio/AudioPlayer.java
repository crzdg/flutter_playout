package tv.mta.flutter_playout.audio;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.util.Log;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.lang.ref.WeakReference;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;
import tv.mta.flutter_playout.MediaNotificationManagerService;
import tv.mta.flutter_playout.PlayerState;

public class AudioPlayer implements MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private final String TAG = "AudioPlayer";

    private AudioServiceBinder audioServiceBinder = null;

    private Handler audioProgressUpdateHandler;

    private EventChannel.EventSink eventSink;

    private Activity activity;

    private Context context;

    private String audioURL;

    private String title;

    private String subtitle;

    private PlayerState playerState;

    private int startPositionInMills;

    private int mediaDuration = 0;

    /**
     * Whether we have bound to a {@link MediaNotificationManagerService}.
     */
    private boolean mIsBoundMediaNotificationManagerService;

    /**
     * The {@link MediaNotificationManagerService} we are bound to.
     */
    private MediaNotificationManagerService mMediaNotificationManagerService;

    /**
     * The {@link ServiceConnection} serves as glue between this activity and the
     * {@link MediaNotificationManagerService}.
     */
    private ServiceConnection mMediaNotificationManagerServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {

            mMediaNotificationManagerService =
                    ((MediaNotificationManagerService.MediaNotificationManagerServiceBinder) service)
                    .getService();

            mMediaNotificationManagerService.setActivePlayer(audioServiceBinder);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

            mMediaNotificationManagerService = null;
        }
    };
    /* This service connection object is the bridge between activity and background service. */
    private ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
            Log.d("ServiceConnection", "onServiceConnected");
            /* Cast and assign background service's onBind method returned iBinder object */
            audioServiceBinder = (AudioServiceBinder) iBinder;

            audioServiceBinder.setActivity(activity);

            audioServiceBinder.setContext(context);

            audioServiceBinder.setAudioProgressUpdateHandler(audioProgressUpdateHandler);

            //audioServiceBinder.setAudioFileUrl(audioURL);

            //audioServiceBinder.setTitle(title);

            //audioServiceBinder.setSubtitle(subtitle);

            //audioServiceBinder.pauseAudio();

            //audioServiceBinder.startAudio(startPositionInMills);

            doBindMediaNotificationManagerService();

            initRadioPlayer();

        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            Log.d("ServiceConnection", "onServiceDisconnected");
        }
    };

    private AudioPlayer(BinaryMessenger messenger, Context context) {

        this.context = context;

        this.audioProgressUpdateHandler = new IncomingMessageHandler(this);

        new MethodChannel(messenger, "tv.mta/NativeAudioChannel")
                .setMethodCallHandler(this);

        new EventChannel(messenger, "tv.mta/NativeAudioEventChannel", JSONMethodCodec.INSTANCE)
                .setStreamHandler(this);
    }

    public static void registerWith(PluginRegistry.Registrar registrar) {

        final AudioPlayer plugin = new AudioPlayer(registrar.messenger(), registrar.activeContext());

        plugin.activity = registrar.activity();

        registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
            @Override
            public boolean onViewDestroy(FlutterNativeView view) {
                plugin.onDestroy();
                return false;
            }
        });
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    private void doBindMediaNotificationManagerService() {

        Intent service = new Intent(this.context,
                MediaNotificationManagerService.class);

        this.context.bindService(service, mMediaNotificationManagerServiceConnection,
                Context.BIND_AUTO_CREATE);

        mIsBoundMediaNotificationManagerService = true;

        this.context.startService(service);
    }

    private void doUnbindMediaNotificationManagerService() {

        if (mIsBoundMediaNotificationManagerService) {

            this.context.unbindService(mMediaNotificationManagerServiceConnection);

            mIsBoundMediaNotificationManagerService = false;
        }
    }

    private void notifyDart(String notification) {
        try {

            JSONObject message = new JSONObject();

            message.put("name", "{}".format(notification));

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notify_{}: ".format(notification), e);
        }
    }


    private void initRadioPlayer(){
        Log.d("initRadioPlayer", "initRadioPlayer");
        audioServiceBinder.initAudioPlayer();
    }

    private void setupRadioPlayer(Object arguments){
        java.util.HashMap<String, Object> args = (java.util.HashMap<String, Object>) arguments;
        this.audioURL = (String) args.get("url");
        this.title = (String) args.get("title");
        this.subtitle = (String) args.get("subtitle");
        audioServiceBinder.setupAudioPlayer(this.audioURL, this.title, this.subtitle);
    }

    private void changeMediaInfo(Object arguments){
        java.util.HashMap<String, Object> args = (java.util.HashMap<String, Object>) arguments;
        this.title = (String) args.get("title");
        this.subtitle = (String) args.get("subtitle");
        audioServiceBinder.setTitle(this.title);
        audioServiceBinder.setSubtitle(this.subtitle);
        if (audioServiceBinder.getPlayerState() == PlayerState.STARTED) {
            audioServiceBinder.updateRadioInformations(this.title, this.subtitle);
        }
            
        notifyDart("onChangeMediaInfo");
    }


    private void play() {

        if (audioServiceBinder != null) {

            audioServiceBinder.startAudio();

        }

    }

    private void pause() {

        if (audioServiceBinder != null) {

            audioServiceBinder.pauseAudio();
        }

    }

    private void reset() {

        if (audioServiceBinder != null) {

            audioServiceBinder.pauseAudio();

            audioServiceBinder.cleanPlayerNotification();

            audioServiceBinder = null;
        }
    }

    private void notifyDartOnError(String errorMessage) {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onError");

            message.put("error", errorMessage);

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notifyDartOnError: ", e);
        }
    }



    /**
     * Bind background service with caller activity. Then this activity can use
     * background service's AudioServiceBinder instance to invoke related methods.
     */
    private void bindAudioService() {

        Log.d("bindAudioService", "bindAudioService");

        if (audioServiceBinder == null) {

            Intent intent = new Intent(this.context, AudioService.class);

            this.context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
        }
    }

    /**
     * Unbound background audio service with caller activity.
     */
    private void unBoundAudioService() {

        if (audioServiceBinder != null) {

            this.context.unbindService(serviceConnection);

            reset();
        }
    }

    @Override
    public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {

        switch (call.method) {
            case "play": {
                play();
                result.success(true);
                break;
            }
            case "pause": {
                pause();
                result.success(true);
                break;
            }
            case "reset": {
                reset();
                result.success(true);
                break;
            }
            case "init": {
                bindAudioService();
                result.success(true);
                break;
            }
            case "dispose": {
                onDestroy();
                result.success(true);
                break;
            }
            case "setup": {
                setupRadioPlayer(call.arguments);
                result.success(true);
                break;
            }
            case "changeMediaInfo": {
                changeMediaInfo(call.arguments);
                result.success(true);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    private void onDestroy() {

        try {

            unBoundAudioService();

            doUnbindMediaNotificationManagerService();

            /* reset media duration */
            mediaDuration = 0;

        } catch (Exception e) { /* ignore */ }
    }

    /* handles messages coming back from AudioServiceBinder */
    static class IncomingMessageHandler extends Handler {

        private final WeakReference<AudioPlayer> mService;

        IncomingMessageHandler(AudioPlayer service) {
            mService = new WeakReference<>(service);
        }

        @Override
        public void handleMessage(Message msg) {

            AudioPlayer service = mService.get();

            if (service != null && service.audioServiceBinder != null) {

                if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_INITIALIZED) {

                    service.notifyDart("onInit");

                }

                else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_READY) {

                    service.notifyDart("onReady");

                }

                else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_START_PLAYING) {

                    service.notifyDart("onStartPlaying");

                }

                else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PLAYING) {

                    service.notifyDart("onPlaying");

                }

                else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PAUSING) {

                    service.notifyDart("onPausing");

                }

                else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PLAYING) {

                    service.notifyDart("onComplete");

                }

            }
        }
    }
}
