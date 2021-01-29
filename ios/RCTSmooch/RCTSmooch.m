#import "RCTSmooch.h"
#import <Smooch/Smooch.h>
#import <UserNotifications/UserNotifications.h>
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

- (BOOL)conversation:(SKTConversation *)conversation shouldShowInAppNotificationForMessage:(SKTMessage *)message {
    NSDictionary *options = message.metadata;
    NSLog(@"Smooch shouldShowInAppNotificationForMessage with %@", options);
    conversationTitle = @"Conversation";
    conversationDescription = options[@"location_display_name"];
    metadata = options;

    return true;
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


@interface NotificationManager
@end

@implementation NotificationManager

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (notification.request.content.userInfo[SKTPushNotificationIdentifier] != nil) { [[Smooch userNotificationCenterDelegate] userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        return;

    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    if (response.notification.request.content.userInfo[SKTPushNotificationIdentifier] != nil) {
        [[Smooch userNotificationCenterDelegate] userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        return;

    }
}

@end

@implementation SmoochManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"unreadCountUpdate"];
}

- (BOOL)isInteger:(NSString *)toCheck {
  if([toCheck intValue] != 0) {
    return true;
  } else if([toCheck isEqualToString:@"0"]) {
    return true;
  } else {
    return false;
  }
}

- (void)sendEvent {
    NSLog(@"sendEvent");
    MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
    NSDictionary *options = [myconversation getMetadata];
    if (options != nil && options[@"short_property_code"] != nil) {
        NSString *name = options[@"short_property_code"];
        [self sendEventWithName:@"unreadCountUpdate" body:@{@"name":name}];
    } else {
        [self sendEventWithName:@"unreadCountUpdate" body:@{@"name":@""}];
    }
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
              MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
              [myconversation setControllerState:self];
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

  [[SKTUser currentUser] addProperties:options];
};

RCT_EXPORT_METHOD(getUserId:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getUserId");

  resolve([SKTUser currentUser].userId);
};

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return [components day];
}
RCT_EXPORT_METHOD(moreMessages) {
  NSLog(@"Smooch moreMessages");
  if ([Smooch conversation].hasPreviousMessages) {
    [Smooch conversation].loadPreviousMessages;
  }
};
RCT_EXPORT_METHOD(getGroupCounts:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getGroupCounts");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  NSInteger totalUnreadCount = 0;

  NSArray *messages = [Smooch conversation].messages;
  NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
  NSDate *now = [NSDate date];

  for (id message in messages) {
      if (message != nil) {
          NSDictionary *options = [message metadata];
          if (options != nil) {
              NSString *name = options[@"short_property_code"];
              NSString *msgId = [message messageId];
              if (msgId != nil) {
                  NSDate *msgDate = [message date];
                  int lengthInDays = [self daysBetween:msgDate and:now];
                  if (lengthInDays < 120) {
                  if (newMessage[name] == nil) {
                      newMessage[name] = @(0);
                  }
                  if (![message isFromCurrentUser]) {
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
          // newMessage[@"name"] = [message name]; // displayName
          // newMessage[@"text"] = [message text];
          NSDate *msgDate = [message date];
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          [formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss"];
          NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
          [formatter setTimeZone:timeZone];
          newMessage[@"date"] = [formatter stringFromDate:msgDate];
          newMessage[@"is_from_current_user"] = @([message isFromCurrentUser]);
          newMessage[@"id"] = [message messageId];
          NSDictionary *options = [message metadata];
          if (options != nil) {
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              if (options[@"location_display_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"location_display_name"];
              } else if (options[@"property_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"property_name"];
              } else {
                for (id message2 in messages) {
                    if (message2 != nil) {
                        NSDictionary *options2 = [message2 metadata];
                        if (options2 != nil && [options[@"short_property_code"] isEqualToString:options2[@"short_property_code"]]) {
                            if (options2[@"location_display_name"] != nil) {
                                newMessage[@"location_display_name"] = options2[@"location_display_name"];
                                break;
                            }
                        }
                    }
                }
                if (newMessage[@"location_display_name"] == nil) {
                    newMessage[@"location_display_name"] = [message name];
                }
              }
          }
          NSString *msgId = [message messageId];
          if ([message isFromCurrentUser]) {
              newMessage[@"is_read"] = @(YES);
          } else if (msgId != nil) {
              BOOL isRead = [db boolForKey:msgId];
              newMessage[@"is_read"] = @(isRead);
          } else {
              newMessage[@"is_read"] = @(NO);
          }
          [newMessages addObject: newMessage];
      }
  }
  resolve(newMessages);
};

RCT_EXPORT_METHOD(getIncomeMessages:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getIncomeMessages");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSMutableArray *newMessages = [[NSMutableArray alloc] init];
  NSArray *messages = [Smooch conversation].messages;
  for (id message in messages) {
      if (message != nil && ![message isFromCurrentUser]) {
          NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
          NSDate *msgDate = [message date];
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          [formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss"];
          NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
          [formatter setTimeZone:timeZone];
          newMessage[@"date"] = [formatter stringFromDate:msgDate];
          NSString *msgId = [message messageId];
          if (msgId != nil) {
            newMessage[@"id"] = msgId; // example: 5fbdc1a608b132000c691500
            BOOL isRead = [db boolForKey:msgId];
            newMessage[@"is_read"] = @(isRead);
          } else {
            newMessage[@"id"] = @"0";
            newMessage[@"is_read"] = @(NO);
          }
          NSDictionary *options = [message metadata];
          if (options != nil) {
            if (options[@"short_property_code"] != nil) {
              // newMessage[@"chat_type"] = @"property";
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              if (options[@"location_display_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"location_display_name"];
              } else {
                newMessage[@"location_display_name"] = [message name];
              }
            } // chat_type of employee and employee_name is not real anymore
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
              if (options[@"location_display_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"location_display_name"];
              } else {
                newMessage[@"location_display_name"] = [message name];
              }
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

RCT_EXPORT_METHOD(setRead:(NSString *)msgId) {
  NSLog(@"Smooch setRead with %@", msgId);
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  [db setBool:@(YES) forKey:msgId];
  [db synchronize];
};

RCT_EXPORT_METHOD(setMetadata:(NSDictionary *)options) {
  NSLog(@"Smooch setMetadata with %@", options);
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setMetadata:options];
  NSLog(@"Smooch getMetadata with %@", [myconversation getMetadata]);
};

RCT_EXPORT_METHOD(updateConversation:(NSString *)title description:(NSString *)description resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch updateConversation with %@", description);
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setTitle:title description:description];
  resolve(@(YES));
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
