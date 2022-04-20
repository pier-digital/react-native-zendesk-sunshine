package com.smooch.rnsmooch;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.Promise;

import java.util.HashMap;
import java.util.Map;

import io.smooch.core.InitializationStatus;
import io.smooch.core.Smooch;
import io.smooch.core.SmoochCallback;
import io.smooch.core.User;
import io.smooch.ui.ConversationActivity;
import io.smooch.core.Message;
import io.smooch.core.Conversation;
import io.smooch.core.LogoutResult;
import io.smooch.core.LoginResult;

public class ReactNativeSmooch extends ReactContextBaseJavaModule {

    private ReactApplicationContext mreactContext;

    @Override
    public String getName() {
        return "SmoochManager";
    }

    private String getExternalId() {
        User currentUser = User.getCurrentUser();
        if (currentUser != null) {
            return currentUser.getExternalId();
        } else {
            return null;
        }
    }

    public ReactNativeSmooch(ReactApplicationContext reactContext) {
        super(reactContext);
        mreactContext = reactContext;
    }

    @ReactMethod
    public void login(final String externalId, final String jwt, final Promise promise) {

        Smooch.login(externalId, jwt, new SmoochCallback<LoginResult>() {
            @Override
            public void run(Response<LoginResult> response) {
              if (promise != null) {
                if (response.getError() != null) {
                    promise.reject("" + response.getStatus(), response.getError());
                    return;
                }
                
                promise.resolve(null);
              }
            }
        });
    }

    @ReactMethod
    public void logout(final Promise promise) {
        Smooch.logout(new SmoochCallback<LogoutResult>() {
            @Override
            public void run(Response<LogoutResult> response) {
                if (response.getError() != null) {
                    promise.reject("" + response.getStatus(), response.getError());
                    return;
                }
                promise.resolve(null);
            }
        });
    }

    @ReactMethod
    public void setNotificationCategory(final Promise promise) {
        // Do nothing! Method specific to iOS. 
        promise.resolve(null);
    }

    @ReactMethod
    public void show() {
        ConversationActivity.builder().withFlags(Intent.FLAG_ACTIVITY_NEW_TASK).show(getReactApplicationContext());
        // v8 ConversationActivity.show(getReactApplicationContext(), Intent.FLAG_ACTIVITY_NEW_TASK);
    }

    @ReactMethod
    public void close() {
        ConversationActivity.close();
    }

    @ReactMethod
    public void getUnreadCount(Promise promise) {
        int unreadCount = Smooch.getConversation().getUnreadCount();
        promise.resolve(unreadCount);
    }

    @ReactMethod
    public void setFirstName(String firstName) {
        User.getCurrentUser().setFirstName(firstName);
    }

    @ReactMethod
    public void setLastName(String lastName) {
        User.getCurrentUser().setLastName(lastName);
    }

    @ReactMethod
    public void setEmail(String email) {
        User.getCurrentUser().setEmail(email);
    }

    @ReactMethod
    public void setUserProperties(final ReadableMap metadata) {
        User.getCurrentUser().addMetadata(getProperties(metadata));
    }

    @ReactMethod
    public void setFirebaseCloudMessagingToken(String fcmToken) {
        Smooch.setFirebaseCloudMessagingToken(fcmToken);
    }

    @ReactMethod
    public void isLoggedIn(final Promise promise) {
        Boolean loginStatus = getExternalId() != null;
        promise.resolve(loginStatus);
    }
    
    private Map<String, Object> getProperties(ReadableMap properties) {
        ReadableMapKeySetIterator iterator = properties.keySetIterator();
        Map<String, Object> props = new HashMap<>();

        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType type = properties.getType(key);
            if (type == ReadableType.Boolean) {
                props.put(key, properties.getBoolean(key));
            } else if (type == ReadableType.Number) {
                props.put(key, properties.getDouble(key));
            } else if (type == ReadableType.String) {
                props.put(key, properties.getString(key));
            }
        }

        return props;
    }
}
