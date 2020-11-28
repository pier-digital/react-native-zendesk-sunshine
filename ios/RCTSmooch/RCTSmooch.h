// SmoochManager.h

#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import "RCTUtils.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTUtils.h>
#endif

#import <Foundation/Foundation.h>
#import <Smooch/SKTConversation.h>

@interface SmoochManager : NSObject <RCTBridgeModule>
@end

@interface MyConversationDelegate : NSObject <SKTConversationDelegate> {
    NSDictionary *metadata;
    NSString *someProperty;
    NSString *conversationTitle;
    NSString *conversationDescription;
}
@property (nonatomic, retain) NSString *someProperty;
@end
