// SmoochManager.h

#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import "RCTUtils.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTUtils.h>
#endif

#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>
#import <Smooch/SKTConversation.h>

@interface SmoochManager : RCTEventEmitter <RCTBridgeModule>
@end

@interface MyConversationDelegate : NSObject <SKTConversationDelegate> {
    NSDictionary *metadata;
    NSString *globalUserId;
    NSString *someProperty;
    NSString *conversationTitle;
    NSString *conversationDescription;
    BOOL hideConversation;
    BOOL sendHideEvent;
    BOOL sendMessageSentEvent;
    id hideId;
}
@property (nonatomic, retain) NSString *someProperty;
+ (id)sharedManager;
- (void)setMetadata:(NSDictionary *)options;
- (void)setTitle:(NSString *)title description:(NSString *)description;
@end
