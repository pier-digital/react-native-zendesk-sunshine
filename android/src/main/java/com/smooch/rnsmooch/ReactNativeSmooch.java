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
import java.util.List;
import java.util.Arrays;

import io.smooch.core.CardSummary;
import io.smooch.core.ConversationDelegate;
import io.smooch.core.MessageModifierDelegate;
import io.smooch.core.ConversationEvent;
import io.smooch.core.InitializationStatus;
import io.smooch.core.MessageAction;
import io.smooch.core.MessageUploadStatus;
import io.smooch.core.PaymentStatus;
import io.smooch.core.Smooch;
import io.smooch.core.SmoochCallback;
import io.smooch.core.SmoochConnectionStatus;
import io.smooch.core.User;
import io.smooch.ui.ConversationActivity;
import io.smooch.core.Message;
import io.smooch.core.Conversation;
import io.smooch.core.ConversationDetails;
import io.smooch.core.LogoutResult;
import io.smooch.core.LoginResult;
import io.smooch.features.conversationlist.ConversationListActivity;

public class ReactNativeSmooch extends ReactContextBaseJavaModule {

    private ReactApplicationContext mreactContext;

    private static final String TriggerMessageText = "[PROACTIVE_TRIGGER]";

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

        setMessageDelegate();
        setConversationDelegate();
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
    public void show(boolean enableMultiConversation) {
        Smooch.getConversationsList(new SmoochCallback<List<Conversation>>() {
            @Override
            public void run(Response<List<Conversation>> response) {
                if (response.getError() != null) {
                    return;
                }

                List<Conversation> conversations = response.getData();
                if (!enableMultiConversation || conversations == null || conversations.isEmpty()) {
                    ConversationActivity.builder()
                        .withFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        .show(getReactApplicationContext());
                }
                else
                {
                    ConversationListActivity.builder()
                        .withFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        .show(getReactApplicationContext());
                }
            }
        });
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

    private void setMessageDelegate() {
        Smooch.setMessageModifierDelegate(new MessageModifierDelegate() {
            @Override
            public Message beforeSend(ConversationDetails conversationDetails, Message message) {
                return message;
            }

            @Override
            public Message beforeDisplay(ConversationDetails conversationDetails, Message message) {
                // TODO: The method getMetadata is still not working. 
                // So we check the text.
                if (message != null && TriggerMessageText.equals(message.getText())) 
                    return null;

                return message;
            }

            @Override
            public Message beforeNotification(String s, Message message) {
                return message;
            }
        });
    }

    private void setConversationDelegate() {
        Smooch.setConversationDelegate(new ConversationDelegate() {
            @Override
            public void onMessagesReceived(@NonNull Conversation conversation, @NonNull List<Message> list) {
            }

            @Override
            public void onMessagesReset(@NonNull Conversation conversation, @NonNull List<Message> list) {
            }

            @Override
            public void onUnreadCountChanged(@NonNull Conversation conversation, int i) {
            }

            @Override
            public void onMessageSent(@NonNull Message message, @NonNull MessageUploadStatus messageUploadStatus) {
            }

            @Override
            public void onConversationEventReceived(@NonNull ConversationEvent conversationEvent) {
            }

            @Override
            public void onInitializationStatusChanged(@NonNull InitializationStatus initializationStatus) {
            }

            @Override
            public void onLoginComplete(@NonNull LoginResult loginResult) {
            }

            @Override
            public void onLogoutComplete(@NonNull LogoutResult logoutResult) {
            }

            @Override
            public void onPaymentProcessed(@NonNull MessageAction messageAction, @NonNull PaymentStatus paymentStatus) {
            }

            @Override
            public boolean shouldTriggerAction(@NonNull MessageAction messageAction) {
                return true;
            }

            @Override
            public void onCardSummaryLoaded(@NonNull CardSummary cardSummary) {
            }

            @Override
            public void onSmoochConnectionStatusChanged(@NonNull SmoochConnectionStatus smoochConnectionStatus) {
            }

            @Override
            public void onSmoochShown() {
                // Force Zendesk to initialize the bot.
                Smooch.getConversationsList(new SmoochCallback<List<Conversation>>() {
                    @Override
                    public void run(Response<List<Conversation>> response) {
                        if (response.getError() != null) {
                            return;
                        }

                        List<Conversation> conversations = response.getData();
                        if (conversations == null || conversations.isEmpty()) {
                            Map<String, Object> metadata = new HashMap<String, Object>();
                            metadata.put("isHidden", true);
                            
                            List<Message> messages = Arrays.asList(new Message(TriggerMessageText, "", metadata));

                            Smooch.createConversation("", "", null, null, messages, null, null);
                        }
                    }
                });
            }

            @Override
            public void onSmoochHidden() {
            }

            @Override
            public void onConversationsListUpdated(@NonNull List<Conversation> list) {
            }
        });
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
