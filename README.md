# react-native-smooch
React Native wrapper for Smooch.io. Based off of [smooch-cordova](https://github.com/smooch/smooch-cordova)

This React Native module was built and tested with version 0.66.3 of React Native. Since React Native is not mature yet, there might be some breaking changes which will break our module. Therefore, if you find a problem, please open an issue.

 ```
    "react": "17.0.2,
    "react-native": "^0.66.3",
 ```

At the moment, this wrapper only covers the most commonly used features of the Smooch SDK. We encourage you to add to this wrapper or make any feature requests you need. Pull requests most definitely welcome!

Please [contact Smooch](mailto:help@smooch.io) for any questions.

Installing Smooch on React Native
=================================

First, make sure you've [signed up for Smooch](https://app.smooch.io/signup)

If you don't already have a React Native application setup, follow the instructions [here](https://facebook.github.io/react-native/docs/getting-started.html) to create one. Make sure you use 0.63.3+.

For React Native 0.60+ you do not need to add anything - it autolinks!

 ```javascript
  "dependencies": {
    "@billnbell/react-native-smooch": "git+https://github.com/billnbell/react-native-sunshine-conversations.git#v1.0.37",
    ...
  }
 ```

 ```
yarn install
 ```


## IOS

 * This uses Smooch IOS SDK v10.1.1

 * You must also have your React dependencies defined in your Podfile as described [here](http://facebook.github.io/react-native/releases/0.31/docs/troubleshooting.html#missing-libraries-for-react), for example:

 * Install pods by `cd ios` and running `pod install`.

 * Open your project's .xcworkspace file in XCode and initialize Smooch with your app id inside of applicationDidFinishLaunchingWithOptions. Or in your App directory/AppDelegate.m file

```
#import <Smooch/Smooch.h>

...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize Smooch - these instructions are also available on [app.smooch.io](https://app.smooch.io)
    SKTSettings *customSettings = [SKTSettings settingsWithIntegrationId:@"YOUR_IOS_INT_ID"];
    [Smooch initWithSettings:customSettings completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
        NSLog(@"Smooch initWithSettings");
        // Your code after init is complete
    }];
}
```

You're now ready to start interacting with Smooch in your React Native app.

## Android

 * this uses Smooch Android SDK v8.0.0+

 * You can easily add a binding to the [Smooch Android SDK](https://github.com/smooch/smooch-android) in your React Native application by following the instructions below.

 * Add `Smooch.init` to the `onCreate` method of your `Application` class.

```java
import io.smooch.core.Settings;
import io.smooch.core.Smooch;
import io.smooch.core.SmoochCallback;
import io.smooch.core.InitializationStatus;

public class MainApplication extends Application implements ReactApplication {
    ...
    @Override
    public void onCreate() {
      super.onCreate();
      SoLoader.init(this, /* native exopackage */ false);
      String integrationId = (BuildConfig.APP_ENV == "PROD") ? BuildConfig.PROD_SMOOCH_INTEGRATION_ID_ANDROID : BuildConfig.STAGE_SMOOCH_INTEGRATION_ID_ANDROID;
      Smooch.init(this, new Settings(integrationId), new SmoochCallback<InitializationStatus>() {
        @Override
        public void run(Response<InitializationStatus> response) {
          // Handle init result
          Log.d("SmoothInit", String.valueOf(response));
        }
      });
      initializeFlipper(this, getReactNativeHost().getReactInstanceManager());
    }
    ...
}
```

You're now ready to start interacting with Smooch in your React Native app.

Using Smooch in your React Native App
=====================================

### Require the module
```javascript
import { Smooch } from 'react-native-smooch';
```
### To set metadata
```javascript
const metadata = {
  short_property_code: chatGroupId,
  property_name: chatGroupName,
};
Smooch.setMetadata(metadata);
```

### Show the conversation screen
```javascript
Smooch.show();
```

### Login to Smooch
```javascript
Smooch.login(smoochUserId, smoochJwt)
  .then(() => {
    console.log('logged in');
  });
```

### Set the user's first name
```javascript
Smooch.setFirstName("Kurt");
```

### Set the user's last name
```javascript
Smooch.setLastName("Osiander");
```

### Set the user's email address
```javascript
Smooch.setEmail("kurt@ralphgraciesf.com");
```

### Turn on events and addListener in React Native
```javascript
Smooch.setSendHideEvent(true);
const subscription = SmoochManagerEmitter
  .addListener('unreadCountUpdate', () => updateUnreadCounts());

Later remove it
  subscription.remove();
```

### To set Title and Description in Conversation Header
```javascript
Smooch.updateConversation('Conversation', label)
  .then(() => {
    console.log('set the header!');
  });
```

### Set the user's sign up date -- not tested
```javascript
Smooch.setSignedUpAt((new Date).getTime());
```

### This module uses internal DB in IOS and Android to keep track of messages read.
```javascript
Smooch.setRead(msgId);
getMessages().then(() => { console.log('got messages') });
to only get those with metadata headers:
getMessagesMetadata(metadata).then(() => { console.log('got messages') });
to get metadata groups  - must have metadata - returns only unread messages and unique short_property_code
getGroupCounts().then(() => { console.log('got messages') });
```

### Associate key/value pairs with the user -- not tested
```javascript
Smooch.setUserProperties({"whenDidYouFsckUp": "aLongTimeAgo"});
```

### s.d.ts (typescript)
```javascript
declare module 'react-native-smooch' {
  class Smooch {
    login(smoochUserId: string, smoochJwt: string): Promise<void>;
    logout(): Promise<void>;
    setNotificationCategory(): Promise<void>;
    setFirstName(firstName: string): void;
    setLastName(lastName: string): void;
    setEmail(email: string): void;
    setMetadata(metadata: object): void;
    setRead(msgId: string): void;
    updateConversation(
      title: string,
      description: string | null,
    ): Promise<void>;
    getMessages(): Promise<IMessage[]>;
    getPushNotificationInfo(): Promise<any>;
    clearPushNotificationInfo(): Promise<any>;
    getIncomeMessages(): Promise<IMessage[]>;
    getMessagesMetadata(metadata: object): Promise<[]>;
    getGroupCounts(): Promise<[]>;
    getGroupCountsIds(): Promise<IGroupIds[]>;
    show(): void;
    close(): void;
    resetLogin(): void;
    setSendHideEvent(hideFlag: boolean): void;
    setMessageSentEvent(isOn: boolean): void;
    getUnreadCount(): Promise<number>;
    triggerNotification(incomeMessage: object): void;
    setFirebaseCloudMessagingToken(token: string): void;
    isLoggedIn(): Promise<boolean>;
  }
  const s = new Smooch();
  class SmoochManagerEmitter {
    addListener(name: string, any): any;
    remove(): void;
  }
  const t = new SmoochManagerEmitter();
  export { s as Smooch, t as SmoochManagerEmitter };
  export type IGroupIds = {
    msgId: string;
    isRead: boolean;
  };

  export type IMessage = {
    id: string;
    is_from_current_user: boolean;
    location_display_name: string;
    short_property_code: string;
    is_read: boolean;
    date: string;
    date_string: string;
  };
}
```

