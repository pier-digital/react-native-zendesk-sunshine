# react-native-smooch
React Native wrapper for Smooch.io. Based off of [smooch-cordova](https://github.com/smooch/smooch-cordova)

This React Native module was built and tested with version 0.63.4 of React Native. Since React Native is not mature yet, there might be some breaking changes which will break our module. Therefore, if you find a problem, please open an issue.

 ```
    "react": "16.13.1",
    "react-native": "^0.63.4",
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
    "@billnbell/react-native-smooch": "git+https://github.com/billnbell/react-native-sunshine-conversations.git#v1.0.4",
    ...
  }
 ```

 ```
yarn install
 ```


## IOS

 * This uses Smooch IOS SDK v7.1.2

 * You must also have your React dependencies defined in your Podfile as described [here](http://facebook.github.io/react-native/releases/0.31/docs/troubleshooting.html#missing-libraries-for-react), for example:

 * Install pods by `cd ios` and running `pod install`.

 * Open your project's .xcworkspace file in XCode and initialize Smooch with your app id inside of applicationDidFinishLaunchingWithOptions. Or in your App directory/AppDelegate.m file

```
#import <Smooch/Smooch.h>

...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize Smooch - these instructions are also available on [app.smooch.io](https://app.smooch.io)
    [Smooch initWithSettings:[SKTSettings settingsWithAppId:@"YOUR_APP_ID"] completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
        NSLog(@"Smooch initWithSettings");
        // Your code after init is complete
    }];
}
```

You're now ready to start interacting with Smooch in your React Native app.

## Android

 * this uses Smooch Android SDK v8.0.0

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
      Smooch.init(this, new Settings("YOUR_APP_ID"), new SmoochCallback<InitializationStatus>() {
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
import { Smooch } from '@billnbell/react-native-smooch';
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
  .addListener('hideConversation', () => updateUnreadCounts());

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
declare module '@billnbell/react-native-smooch' {
  class Smooch {
    login(smoochUserId: string, smoochJwt: string): Promise<void>;
    logout(): Promise<void>;
    setFirstName(firstName: string): void;
    setLastName(lastName: string): void;
    setEmail(email: string): void;
    setMetadata(metadata: object): void;
    setRead(msgId: string): void;
    updateConversation(title: string, description: string | null): Promise<void>;
    getMessages(): Promise<[]>;
    getIncomeMessages(): Promise<IMessage[]>;
    getMessagesMetadata(metadata: object): Promise<string>;
    getGroupCounts(): Promise<string>;
    show(): Promise<boolean>;
    setSendHideEvent(hideFlag: boolean): void;
    getUnreadCount(): Promise<number>;
  }
  const s = new Smooch();
  class SmoochManagerEmitter {
    addListener(name: string, any): any;
    remove(): void;
  }
  const t = new SmoochManagerEmitter();
  export { s as Smooch, t as SmoochManagerEmitter};
  export type IMessage  = {
    chat_type: string,
    id: string,
    location_display_name: string,
    short_property_code: string,
    is_read: boolean,
    date: string,
    date_string: string,
  }
}
```

