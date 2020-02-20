//
//  BAEDisplayReceiptHelper.h
//  BatchExtension
//
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

// Public API

NS_ASSUME_NONNULL_BEGIN

/**
Batch Extension Display receipt helper.
You should instanciate this once per UNNotificationServiceExtension and use the same instance for everything, as some methods might need context.
*/
@interface BAEDisplayReceiptHelper : NSObject

/**
Send the display receipt to Batch server if necessary.

This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly, and preprocess your content before giving it to this method

- Parameter content: Notification content
- Parameter completionHandler: Completion block
*/
- (void)processDisplayReceipt:(UNNotificationContent*)content completionHandler:(void (^)(UNNotificationContent* _Nullable result, NSError* _Nullable error))completionHandler;

/**
 Cache and send display receipts
 
 This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly
 
 - Parameter content: Notification content
 */
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request API_AVAILABLE(ios(10));

/**
Call this to notify Batch that the same method of the standard iOS delegate has been called
*/
- (void)serviceExtensionTimeWillExpire API_AVAILABLE(ios(10));

@end

NS_ASSUME_NONNULL_END
