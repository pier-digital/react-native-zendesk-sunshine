#import "RCTSmooch.h"
#import <Smooch/Smooch.h>
#import <Smooch/SKTMessage.h>
#import <Smooch/SKTConversation.h>

@interface MyConversationDelegate()
@end

@interface SmoochManager()
- (void)sendEvent;
@end

@implementation MyConversationDelegate
@synthesize someProperty;

- (SKTMessage *)conversation:(SKTConversation *)conversation willSendMessage:(SKTMessage *)message {
    NSLog(@"Smooch willSendMessage with %@", message);
    NSLog(@"Metadata", metadata);
    [message setMetadata:metadata];
    return message;
}

- (nullable SKTMessage *)conversation:(SKTConversation *)conversation willDisplayMessage:(SKTMessage *)message {
    NSLog(@"Smooch willDisplay with %@", message);
    NSLog(@"Metadata", metadata);
    NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
    if (message != nil) {
      NSDictionary *options = message.metadata;
      if ([options[@"short_property_code"] isEqualToString:metadata[@"short_property_code"]]) {
        NSString *msgId = [message messageId];
        if (msgId != nil) {
            BOOL isRead = [db boolForKey:msgId]; // return NO if not exists
            if (!isRead) {
              [db setBool:@(YES) forKey:msgId];
              [db synchronize];
            }
        }
        return message;
      }
    }
    return nil;
}

- (void)conversation:(SKTConversation *)conversation willShowViewController:(UIViewController *)viewController {
    if (viewController != nil && conversationTitle != nil && conversationDescription != nil) {
        UINavigationItem *navigationItem = viewController.navigationItem;
        NSString *fullTitle = [NSString stringWithFormat:@"%@ (%@)", conversationTitle, conversationDescription];
        UIStackView *titleView = [[UIStackView alloc] init];
        titleView.axis = UILayoutConstraintAxisVertical;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = UITextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:20];
        titleLabel.textColor = UIColor.darkGrayColor;
        titleLabel.text = conversationTitle;
        
        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.textAlignment = UITextAlignmentCenter;
        subtitleLabel.font = [UIFont systemFontOfSize:13];
        subtitleLabel.textColor = UIColor.darkGrayColor;
        subtitleLabel.text = conversationDescription;
        
        [titleView addArrangedSubview:titleLabel];
        [titleView addArrangedSubview:subtitleLabel];
        [titleView sizeToFit];
        
        // [navigationItem setTitle:fullTitle];
        [navigationItem setTitleView:titleView];
    }
}

-(void)conversation:(SKTConversation *)conversation willDismissViewController:(UIViewController*)viewController {
    if (sendHideEvent) {
        [hideId sendEvent];
    }
    hideConversation = YES;
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

- (void)setMetadata:(NSDictionary *)options {
    NSLog(@"Smooch setMetadata");
    metadata = options;
    if ([Smooch conversation] != nil) {
        [Smooch conversation].delegate = self;
    }
}
- (NSDictionary *)getMetadata {
    NSLog(@"Smooch getMetadata");
    return metadata;
}

- (void)setSendHideEvent:(BOOL)hideEvent {
    NSLog(@"Smooch setSendHideEvent");
    sendHideEvent = hideEvent;
}

- (BOOL)getSendHideEvent {
    NSLog(@"Smooch getSendHideEvent");
    return sendHideEvent;
}

- (void)setTitle:(NSString *)title description:(NSString *)description {
    NSLog(@"Smooch setTitle");
    conversationTitle = title;
    conversationDescription = description;
    if ([Smooch conversation] != nil) {
        [Smooch conversation].delegate = self;
    }
}

- (void)setControllerState:(id)callEvent {
    if ([Smooch conversation] != nil) {
        [Smooch conversation].delegate = self;
    }
    hideConversation = NO;
    hideId = callEvent;
}

- (BOOL)getControllerState {
    return hideConversation;
}
@end

@implementation SmoochManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"hideConversation"];
}

- (void)sendEvent {
    NSLog(@"sendEvent");
    MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
    NSDictionary *options = [myconversation getMetadata];
    if (options != nil && options[@"short_property_code"] != nil) {
        NSString *name = options[@"short_property_code"];
        [self sendEventWithName:@"hideConversation" body:@{@"name":name}];
    } else {
        [self sendEventWithName:@"hideConversation" body:@{@"name":@""}];
    }
}

RCT_EXPORT_METHOD(show:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch Show");

  dispatch_async(dispatch_get_main_queue(), ^{
    [Smooch show];
    MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
    [myconversation setControllerState:self];
    resolve(@(NO));
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

  dispatch_async(dispatch_get_main_queue(), ^{
      [Smooch login:externalId jwt:jwt completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
          if (error) {
              NSLog(@"Error Login");
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
};

RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch Logout");

  dispatch_async(dispatch_get_main_queue(), ^{
      [Smooch logoutWithCompletionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
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
};

RCT_EXPORT_METHOD(setUserProperties:(NSDictionary*)options) {
  NSLog(@"Smooch setUserProperties with %@", options);

    // [[SKTUser currentUser] addMetadata:options];
  [[SKTUser currentUser] addProperties:options];
};

RCT_EXPORT_METHOD(getUserId:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getUserId");

  resolve([SKTUser currentUser].userId);
};

RCT_EXPORT_METHOD(getGroupCounts:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getGroupCounts");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  NSInteger totalUnreadCount = 0;

  NSArray *messages = [Smooch conversation].messages;
  NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
    
  for (id message in messages) {
      if (message != nil) {
          NSDictionary *options = [message metadata];
          if (options != nil) {
              NSString *name = options[@"short_property_code"];
              NSString *msgId = [message messageId];
              if (msgId != nil) {
                  if (newMessage[name] == nil) {
                      newMessage[name] = @(0);
                  }
                  BOOL isRead = [db boolForKey:msgId];
                  if (!isRead) {
                      totalUnreadCount += 1;
                      NSNumber *count = newMessage[name];
                      newMessage[name] = [NSNumber numberWithInt:[count intValue] + 1];
                  }
              }
          }
      }
  }

  NSMutableArray *groups = [[NSMutableArray alloc] init];
    
  NSMutableDictionary *totalMessage = [[NSMutableDictionary alloc] init];
  totalMessage[@"totalUnReadCount"] = @(totalUnreadCount);
  [groups addObject: totalMessage];
    
  for (NSString *key in newMessage) {
      NSInteger value = [newMessage[key] longValue];
      NSMutableDictionary *tMsg = [[NSMutableDictionary alloc] init];
      tMsg[@"short_property_code"] = key;
      tMsg[@"unReadCount"] = @(value);
      [groups addObject: tMsg];
  }
    
  resolve(groups);
};

RCT_EXPORT_METHOD(getMessages:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getMessages");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSMutableArray *newMessages = [[NSMutableArray alloc] init];
  NSArray *messages = [Smooch conversation].messages;
  for (id message in messages) {
      if (message != nil) {
          NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
          newMessage[@"name"] = [message name]; // displayName
          newMessage[@"text"] = [message text];
          newMessage[@"isFromCurrentUser"] = @([message isFromCurrentUser]);
          newMessage[@"messageId"] = [message messageId];
          NSDictionary *options = [message metadata];
          if (options != nil) {
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              newMessage[@"location_display_name"] = options[@"location_display_name"];
          }
          NSString *msgId = [message messageId];
          if ([message isFromCurrentUser]) {
              newMessage[@"isRead"] = @(YES);
          } else if (msgId != nil) {
              BOOL isRead = [db boolForKey:msgId];
              newMessage[@"isRead"] = @(isRead);
          } else {
              newMessage[@"isRead"] = @(NO);
          }
          [newMessages addObject: newMessage];
      }
  }
  resolve(newMessages);
};

RCT_EXPORT_METHOD(getMessagesMetadata:(NSDictionary *)metadata resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getMessagesMetadata");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSMutableArray *newMessages = [[NSMutableArray alloc] init];
  NSArray *messages = [Smooch conversation].messages;
  for (id message in messages) {
    if (message != nil) {
      NSDictionary *options = [message metadata];
      if ([options[@"short_property_code"] isEqualToString:metadata[@"short_property_code"]]) {
          NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
          newMessage[@"name"] = [message name]; // displayName
          newMessage[@"text"] = [message text];
          newMessage[@"isFromCurrentUser"] = @([message isFromCurrentUser]);
          newMessage[@"messageId"] = [message messageId];
          NSDictionary *options = [message metadata];
          if (options != nil) {
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              newMessage[@"location_display_name"] = options[@"location_display_name"];
          }
          NSString *msgId = [message messageId];
          if ([message isFromCurrentUser]) {
              newMessage[@"isRead"] = @(YES);
          } else if (msgId != nil) {
              BOOL isRead = [db boolForKey:msgId];
              newMessage[@"isRead"] = @(isRead);
          } else {
              newMessage[@"isRead"] = @(NO);
          }
          [newMessages addObject: newMessage];
      }
    }
  }
  resolve(newMessages);
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

RCT_EXPORT_METHOD(setSendHideEvent:(BOOL)hideEvent) {
  NSLog(@"Smooch setSendHideEvent");
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setSendHideEvent:hideEvent];
};

RCT_EXPORT_METHOD(setMetadata:(NSDictionary *)options) {
  NSLog(@"Smooch setMetadata with %@", options);
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setMetadata:options];
  NSLog(@"Smooch getMetadata with %@", [myconversation getMetadata]);
};

RCT_EXPORT_METHOD(updateConversation:(NSString *)title description:(NSString *)description) {
  NSLog(@"Smooch updateConversation with %@", description);
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setTitle:title description:description];
};

// Version 9.0.0
//
//RCT_EXPORT_METHOD(updateConversation:(NSString*)title description:(NSString*)description  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
//
//  NSLog(@"Smooch updateConversation with %@", description);
//
//  NSString *conversationId = [Smooch conversation].conversationId;
//  if (conversationId != nil) {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [Smooch updateConversationById:conversationId withName:title description:description iconUrl:nil metadata:nil completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
//            if (error) {
//                reject(
//                   userInfo[SKTErrorCodeIdentifier],
//                   userInfo[SKTErrorDescriptionIdentifier],
//                   error);
//            }
//            else {
//                resolve(userInfo);
//            }
//        }];
//    });
//  }
//};


@end
