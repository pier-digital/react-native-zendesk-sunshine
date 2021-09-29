#import "RCTSmooch.h"
#import <Smooch/Smooch.h>
#import <UserNotifications/UserNotifications.h>
#import <Smooch/SKTMessage.h>
#import <Smooch/SKTConversation.h>

@interface MyConversationDelegate()
@end

@interface SmoochManager()
- (void)sendEvent;
- (void)sendMessageSentEvent;
- (void)sendUnreadCountUpdate;
@end

@implementation MyConversationDelegate
@synthesize someProperty;

- (SKTMessage *)conversation:(SKTConversation *)conversation willSendMessage:(SKTMessage *)message {
    NSLog(@"Smooch willSendMessage with %@", message);
    NSLog(@"Metadata %@", metadata);
    [message setMetadata:metadata];
    if (sendMessageSentEvent) {
      [hideId sendMessageSentEvent];
    }
    return message;
}

- (nullable SKTMessage *)conversation:(SKTConversation *)conversation willDisplayMessage:(SKTMessage *)message {
    NSLog(@"Smooch willDisplay with %@", message);
    NSLog(@"Metadata %@", metadata);
    MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
    NSString *globalUserId = [myconversation getGlobalUserId];
    NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
    if (message != nil) {
      NSDictionary *options = message.metadata;
      if ([options[@"short_property_code"] isEqualToString:metadata[@"short_property_code"]]) {
        NSString *msgId = [message messageId];
        if (msgId != nil) {
            NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];
            BOOL isRead = [db boolForKey:localMsgId]; // return NO if not exists
            if (!isRead) {
              [db setBool:YES forKey:localMsgId];
              [db synchronize];
            }
        }

        return message;
      }
    }
    return nil;
}

- (BOOL)hideIdSendUnreadCountUpdate {
    NSLog(@"Smooch hideIdSendUnreadCountUpdate");
    if (sendHideEvent) {
      [hideId sendUnreadCountUpdate];
    }
    return YES;
}
- (BOOL)conversation:(SKTConversation *)conversation shouldShowInAppNotificationForMessage:(SKTMessage *)message {
    NSDictionary *metadata = message.metadata;
    NSLog(@"Smooch shouldShowInAppNotificationForMessage with %@", metadata);
    // just return YES and dont save anything
    if (sendHideEvent) {
      [hideId sendUnreadCountUpdate];
    }
    return YES;
}

- (BOOL)conversation:(SKTConversation *)conversation shouldShowForAction:(SKTAction)action withInfo:(nullable NSDictionary *)info {
    NSLog(@"Smooch shouldShowForAction %@", info);
    MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
    if (action == SKTActionInAppNotificationTapped || action == SKTActionPushNotificationTapped) {
        if (info[@"message"] != nil) {
            if (info[@"message"][@"message"] != nil && info[@"message"][@"message"][@"metadata"] != nil ) {
                NSString *description = info[@"message"][@"message"][@"metadata"][@"location_display_name"];
                NSLog(@"Double Smooch shouldShowForAction description %@", description);
                NSDictionary *meta = info[@"message"][@"message"][@"metadata"];
                NSLog(@"Double Smooch shouldShowForAction meta %@", meta);
                [myconversation setMetadata:meta];
                [myconversation setTitle:@"Conversation" description:description];
            } else if (info[@"message"] != nil && info[@"message"][@"metadata"] != nil ) {
                NSString *description = info[@"message"][@"metadata"][@"location_display_name"];
                NSLog(@"Smooch shouldShowForAction description %@", description);
                NSDictionary *meta = info[@"message"][@"metadata"];
                NSLog(@"Smooch shouldShowForAction meta %@", meta);
                [myconversation setMetadata:meta];
                [myconversation setTitle:@"Conversation" description:description];
            }
        }
    }

    return YES;
}

- (void)conversation:(SKTConversation *)conversation willShowViewController:(UIViewController *)viewController {
    if (viewController != nil && conversationTitle != nil && conversationDescription != nil) {
        UINavigationItem *navigationItem = viewController.navigationItem;
        UIStackView *titleView = [[UIStackView alloc] init];
        titleView.axis = UILayoutConstraintAxisVertical;

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:20];
        titleLabel.textColor = UIColor.darkGrayColor;
        titleLabel.text = conversationTitle;

        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.font = [UIFont systemFontOfSize:13];
        subtitleLabel.textColor = UIColor.darkGrayColor;
        subtitleLabel.text = conversationDescription;

        [titleView addArrangedSubview:titleLabel];
        [titleView addArrangedSubview:subtitleLabel];
        [titleView sizeToFit];

        // [navigationItem setLeftBarButtonItems:nil animated:NO];
        [navigationItem setTitleView:titleView ];
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

- (void)setEmail:(NSString *)iEmail {
    NSLog(@"Smooch setEmail");
    email = iEmail;
}

- (NSString *)getEmail {
    NSLog(@"Smooch getEmail");
    return email;
}

- (NSString *)getGlobalUserId {
    NSLog(@"Smooch getGlobalUserId");
    return globalUserId;
}

- (void)setGlobalUserId:(NSString *)userId {
    NSLog(@"Smooch setGlobalUserId");
    globalUserId = userId;
}

- (void)setSendHideEvent:(BOOL)hideEvent {
    NSLog(@"Smooch setSendHideEvent");
    sendHideEvent = hideEvent;
}

- (BOOL)getSendHideEvent {
    NSLog(@"Smooch getSendHideEvent");
    return sendHideEvent;
}

- (void)setMessageSentEvent:(BOOL)isSet {
    NSLog(@"Smooch setMessageSentEvent");
    sendMessageSentEvent = isSet;
}

- (BOOL)getMessageSentEvent {
    NSLog(@"Smooch getMessageSentEvent");
    return sendMessageSentEvent;
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
    if (callEvent != nil) {
        hideId = callEvent;
    }
}

- (BOOL)getControllerState {
    return hideConversation;
}
@end

@implementation SmoochManager

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"unreadCountUpdate", @"messageSent"];
}

- (BOOL)isInteger:(NSString *)toCheck {
  if([toCheck intValue] != 0) {
    return YES;
  } else if([toCheck isEqualToString:@"0"]) {
    return YES;
  } else {
    return NO;
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

- (void)sendMessageSentEvent {
    NSLog(@"sendMessageSentEvent");
    [self sendEventWithName:@"messageSent" body:@{@"name":@""}];
}
- (void)sendUnreadCountUpdate {
    NSLog(@"sendUnreadCountUpdate");
    [self sendEventWithName:@"unreadCountUpdate" body:@{@"name":@""}];
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
              [myconversation setControllerState:self];
              [myconversation setGlobalUserId:externalId];
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
              MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
              [myconversation setGlobalUserId:nil];
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
    // [[SKTUser currentUser] addMetadata:options];
    [[SKTUser currentUser] addProperties:options];
};
RCT_EXPORT_METHOD(resetLogin) {
  NSLog(@"Smooch resetLogin");
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setControllerState:self];
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
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
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
                      NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];
                    BOOL isRead = [db boolForKey:localMsgId];
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

RCT_EXPORT_METHOD(getGroupCountsIds:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getGroupCountsIds");
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSArray *messages = [Smooch conversation].messages;
  NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
  NSDate *now = [NSDate date];

  for (id message in messages) {
      if (message != nil) {
          NSDictionary *options = [message metadata];
          if (options != nil) {
              NSString *msgId = [message messageId];
              if (msgId != nil) {
                  NSDate *msgDate = [message date];
                  int lengthInDays = [self daysBetween:msgDate and:now];
                  if (lengthInDays < 120) {
                  if (![message isFromCurrentUser]) {
                    NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];

                    BOOL isRead = [db boolForKey:localMsgId];
                    if (!isRead) {
                        newMessage[msgId] = @(NO);
                    } else {
                        newMessage[msgId] = @(YES);
                    }
                  } else {
                    newMessage[msgId] = @(YES);
                  }
                }
              }
          }
      }
  }

  NSMutableArray *groups = [[NSMutableArray alloc] init];

  for (NSString *key in newMessage) {
      BOOL value = [newMessage[key] boolValue];
      NSMutableDictionary *tMsg = [[NSMutableDictionary alloc] init];
      tMsg[@"msgId"] = key;
      tMsg[@"isRead"] = @(value);
      [groups addObject: tMsg];
  }

  resolve(groups);
};

// only IOS needs this
RCT_EXPORT_METHOD(getPushNotificationInfo:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getPushNotificationInfo");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  NSString *shortCode = [db valueForKey:@"shortCode"];
  NSString *name = [db valueForKey:@"name"];
  NSString *title = [db valueForKey:@"locationDisplayName"];
  NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
  if (shortCode == nil) {
      newMessage[@"short_property_code"] = @"";
  } else {
      newMessage[@"short_property_code"] = shortCode;
  }
  if (name == nil) {
      newMessage[@"name"] = @"";
  } else {
      newMessage[@"name"] = name;
  }
  if (title == nil) {
    newMessage[@"location_display_name"] = @"";
  } else {
    newMessage[@"location_display_name"] = title;
  }
  resolve(newMessage);
}

RCT_EXPORT_METHOD(clearPushNotificationInfo:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch clearPushNotificationInfo");
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  NSString *clear = @"";
  [db setObject:clear forKey:@"shortCode"];
  [db setObject:clear forKey:@"name"];
  [db setObject:clear forKey:@"locationDisplayName"];
  [db synchronize];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(getMessages:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"Smooch getMessages");
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSMutableArray *newMessages = [[NSMutableArray alloc] init];
  NSArray *messages = [Smooch conversation].messages;
  for (id message in messages) {
      if (message != nil) {
          NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
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
                    // newMessage[@"location_display_name"] = [message displayName]; // V8
                    newMessage[@"location_display_name"] = [message name];
                }
              }
          }
          NSString *msgId = [message messageId];
          if ([message isFromCurrentUser]) {
              newMessage[@"is_read"] = @(YES);
          } else if (msgId != nil) {
              NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];
              BOOL isRead = [db boolForKey:localMsgId];
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
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
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
            NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];
            BOOL isRead = [db boolForKey:localMsgId];
            newMessage[@"is_read"] = @(isRead);
          } else {
            newMessage[@"id"] = @"0";
            newMessage[@"is_read"] = @(NO);
          }
          NSDictionary *options = [message metadata];
          if (options != nil) {
            if (options[@"short_property_code"] != nil) {
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              if (options[@"location_display_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"location_display_name"];
              } else {
                // newMessage[@"location_display_name"] = [message displayName]; // V8
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
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];

  NSMutableArray *newMessages = [[NSMutableArray alloc] init];
  NSArray *messages = [Smooch conversation].messages;
  for (id message in messages) {
    if (message != nil) {
      NSDictionary *options = [message metadata];
      if ([options[@"short_property_code"] isEqualToString:metadata[@"short_property_code"]]) {
          NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
          newMessage[@"name"] = [message name];
          // newMessage[@"name"] = [message displayName]; // V8
          newMessage[@"text"] = [message text];
          newMessage[@"isFromCurrentUser"] = @([message isFromCurrentUser]);
          newMessage[@"messageId"] = [message messageId];
          NSDictionary *options = [message metadata];
          if (options != nil) {
              newMessage[@"short_property_code"] = options[@"short_property_code"];
              if (options[@"location_display_name"] != nil) {
                newMessage[@"location_display_name"] = options[@"location_display_name"];
              } else {
                // newMessage[@"location_display_name"] = [message displayName]; // V8
                newMessage[@"location_display_name"] = [message name];
              }
          }
          NSString *msgId = [message messageId];
          if ([message isFromCurrentUser]) {
              newMessage[@"isRead"] = @(YES);
          } else if (msgId != nil) {
              NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];

              BOOL isRead = [db boolForKey:localMsgId];
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
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setEmail:email];
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

RCT_EXPORT_METHOD(setMessageSentEvent:(BOOL)isSet) {
  NSLog(@"Smooch setMessageSentEvent");
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setMessageSentEvent:isSet];
};

RCT_EXPORT_METHOD(setRead:(NSString *)msgId) {
  NSLog(@"Smooch setRead with %@", msgId);
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  NSString *globalUserId = [myconversation getGlobalUserId];
  NSUserDefaults *db = [NSUserDefaults standardUserDefaults];
  NSString *localMsgId = globalUserId == nil ? msgId : [NSString stringWithFormat:@"%@%@", globalUserId, msgId];
  [db setBool:YES forKey:localMsgId];
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
  MyConversationDelegate *myconversation = [MyConversationDelegate sharedManager];
  [myconversation setGlobalUserId:externalId];
  resolve(@(isLogged));
};
@end
