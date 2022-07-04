#import "RCTSmooch.h"
#import <Smooch/Smooch.h>
#import <UserNotifications/UserNotifications.h>
#import <Smooch/SKTMessage.h>
#import <Smooch/SKTConversation.h>

@interface MyConversationDelegate()
@end

@interface SmoochManager()
@end

NSString *TriggerMessageText = @"PROACTIVE_TRIGGER";

@implementation MyConversationDelegate
- (void)conversation:(SKTConversation *)conversation willShowViewController:(UIViewController *)viewController
{
  [Smooch getConversations: ^(NSError *_Nullable error, NSArray *_Nullable conversations) {
    NSDictionary *msgMetadata = @{@"isHidden": @YES};
    NSArray<SKTMessage *> *proactiveTriggerMessage = @[[[SKTMessage alloc] initWithText:TriggerMessageText payload:@"" metadata:msgMetadata]];
    if (conversations == nil || [conversations count] == 0) {
    [Smooch createConversationWithName: nil
                            description: nil iconUrl:nil avatarUrl:nil metadata: nil message:proactiveTriggerMessage completionHandler: nil];
    }
  }];
}

- (nullable SKTMessage *)conversation:(SKTConversation *)conversation willDisplayMessage:(SKTMessage *)message{
    if(message != nil && [message.text isEqualToString:TriggerMessageText]){
        return nil;
    }
    return message;
}

- (void)setControllerState {
    if ([Smooch conversation] != nil) {
        [Smooch conversation].delegate = self;
    }
}

+ (id)sharedManager {
    static MyConversationDelegate *sharedMyManager = nil;
    @synchronized(self) {
        if (sharedMyManager == nil) {
            sharedMyManager = [[self alloc] init];
        }
    }
    return sharedMyManager;
}
@end

@implementation SmoochManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[];
}

RCT_EXPORT_METHOD(show) {
  NSLog(@"Smooch Show");

  dispatch_async(dispatch_get_main_queue(), ^{
    [Smooch show];
  });
};

RCT_EXPORT_METHOD(close) {
  NSLog(@"Smooch Close");

  dispatch_async(dispatch_get_main_queue(), ^{
    [Smooch close];
  });
};

RCT_EXPORT_METHOD(login:(NSString*)externalId jwt:(NSString*)jwt resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch Login");
  __block BOOL done = NO;
  // set timeout of 10 seconds and return NULL

  dispatch_async(dispatch_get_main_queue(), ^{
      [Smooch login:externalId jwt:jwt completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
          done = YES;
          if (error) {
              NSLog(@"Error Login");
              reject(
                 userInfo[SKTErrorCodeIdentifier],
                 userInfo[SKTErrorDescriptionIdentifier],
                 error);
          }
          else {
              NSLog(@"Success Login");

              MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
              [myconversation setControllerState];

              resolve(userInfo);
          }
      }];
  });

  // set timeout of 10 seconds and return NULL
  dispatch_time_t time =  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC));
  dispatch_after(time, dispatch_get_main_queue(), ^{
        if (!done) {
          done = YES;
          resolve(NULL);
        }
  });
};

RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch Logout");
  __block BOOL done = NO;

  dispatch_async(dispatch_get_main_queue(), ^{
      [Smooch logoutWithCompletionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
          done = YES;
          if (error) {
              reject(
                     userInfo[SKTErrorCodeIdentifier],
                     userInfo[SKTErrorDescriptionIdentifier],
                     error);
          }
          else {
              resolve(userInfo);
          }
      }];
  });
  dispatch_time_t time =  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC));
  dispatch_after(time, dispatch_get_main_queue(), ^{
        if (!done) {
          done = YES;
          resolve(NULL);
        }
  });
};

RCT_EXPORT_METHOD(setNotificationCategory:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"Smooch setNotificationCategory");
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionBadge + UNAuthorizationOptionSound)
       completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) {
            NSLog(@"Smooch setNotificationCategory not granted");
            resolve(NULL);
        } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
                [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[Smooch userNotificationCategories]];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            } else {
                UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:[Smooch userNotificationCategories]];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            }

            NSLog(@"Smooch setNotificationCategory categories");
            resolve(NULL);
        });
        }
    }];
};

RCT_EXPORT_METHOD(setUserProperties:(NSDictionary*)options) {
  NSLog(@"Smooch setUserProperties with %@", options);
    [[SKTUser currentUser] addMetadata:options];
};

RCT_REMAP_METHOD(getUnreadCount,
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getUnreadCount");

  long unreadCount = [Smooch conversation].unreadCount;
  resolve(@(unreadCount));
};

RCT_EXPORT_METHOD(setFirstName:(NSString*)firstName) {
  NSLog(@"Smooch setFirstName");

  [SKTUser currentUser].firstName = firstName;
};

RCT_EXPORT_METHOD(setLastName:(NSString*)lastName) {
  NSLog(@"Smooch setLastName");

  [SKTUser currentUser].lastName = lastName;
};

RCT_EXPORT_METHOD(setEmail:(NSString*)email) {
  NSLog(@"Smooch setEmail");

  [SKTUser currentUser].email = email;
};

RCT_EXPORT_METHOD(setSignedUpAt:(NSDate*)date) {
  NSLog(@"Smooch setSignedUpAt");

  [SKTUser currentUser].signedUpAt = date;
};

RCT_EXPORT_METHOD(setFirebaseCloudMessagingToken:(NSString*)token) {
    NSLog(@"Smooch setFirebaseCloudMessagingToken %@", token);
    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    [Smooch setPushToken:(tokenData)];
};

RCT_EXPORT_METHOD(isLoggedIn:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // NSString *externalId = [SKTUser currentUser].externalId;
  NSString *externalId = [SKTUser currentUser].userId;
  BOOL isLogged = externalId != nil;
  NSLog(@"Smooch isLoggedIn %@", @(isLogged));
  resolve(@(isLogged));
};
@end
