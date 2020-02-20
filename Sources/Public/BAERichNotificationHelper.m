//
//  BAERichNotificationHelper.m
//  BatchExtension
//
//  Copyright © 2016 Batch.com. All rights reserved.
//

#import "BAERichNotificationHelper.h"

#import "Consts.h"

#define ERROR_DOMAIN @"com.batch.extension.richnotificationhelper"

@interface BAERichNotificationAttachment : NSObject

@property (nonnull) NSURL *url;
@property (nonnull) NSString *type;

@end

@implementation BAERichNotificationAttachment
@end

@implementation BAERichNotificationHelper

static BOOL _baeRichHelperAllowInLowDataMode = false;

+ (void)setAllowInLowDataMode:(BOOL)allow {
    _baeRichHelperAllowInLowDataMode = allow;
}

+ (BOOL)allowInLowDataMode {
  return _baeRichHelperAllowInLowDataMode;
}

- (void)appendRichDataToContent:(UNNotificationContent*)content completionHandler:(void (^)(UNNotificationContent *result, NSError *error))completionHandler
{
    if (content == nil)
    {
        completionHandler(nil, [NSError errorWithDomain:ERROR_DOMAIN
                                                   code:-1
                                               userInfo:@{NSLocalizedDescriptionKey: @"No source notification content was provided"}]);
    }
    
    BAERichNotificationAttachment *attachment = [self attachmentForPayload:content.userInfo];
    if (attachment)
    {
        [self downloadAttachment:attachment completionHandler:^(NSURL *location, NSString *typeHint, NSError *error) {
            if (error)
            {
                completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                           code:-2
                                                       userInfo:@{NSLocalizedDescriptionKey: @"An error occurred while downloading the attachment",
                                                                  NSUnderlyingErrorKey: error}]);
                return;
            }
            
            if (location != nil)
            {
                NSError *attachmentErr;
                UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:BA_ATTACHMENT_IDENTIFIER
                                                                                                      URL:location
                                                                                                  options:@{UNNotificationAttachmentOptionsTypeHintKey: typeHint}
                                                                                                    error:&attachmentErr];
                
                if (attachmentErr != nil)
                {
                    completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                               code:-4
                                                           userInfo:@{NSLocalizedDescriptionKey: @"An error occurred while creating the attachment",
                                                                      NSUnderlyingErrorKey: attachmentErr}]);
                }
                else
                {
                    UNMutableNotificationContent *mutableContent = [content mutableCopy];
                    mutableContent.attachments = [mutableContent.attachments arrayByAddingObject:attachment];
                    completionHandler(mutableContent, nil);
                }
            }
            else
            {
                completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                           code:-3
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}]);
            }
        }];
    }
    else
    {
        completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                       code:-5
                                                   userInfo:@{NSLocalizedDescriptionKey: @"No additional data to append found"}]);
    }
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler
{
    [self appendRichDataToContent:request.content completionHandler:^(UNNotificationContent * _Nonnull result, NSError * _Nonnull error) {
        if (error)
        {
            NSLog(@"Batch - An error occurred while downloading the rich push: %@", error);
        }
        contentHandler(result != nil ? result : request.content);
    }];
}

- (void)serviceExtensionTimeWillExpire
{
    // Nothing yet, but maybe we will
}

#pragma mark Private methods

- (BAERichNotificationAttachment*)attachmentForPayload:(NSDictionary*)userInfo
{
    if (userInfo == nil)
    {
        return nil;
    }
    
    NSDictionary *batchPayload = [userInfo objectForKey:@"com.batch"];
    if (![batchPayload isKindOfClass:[NSDictionary class]])
    {
        return nil;
    }
    
    NSDictionary *attachment = [batchPayload objectForKey:@"at"];
    if (![attachment isKindOfClass:[NSDictionary class]])
    {
        return nil;
    }
    
    NSString *urlString = [attachment objectForKey:@"u"]; // https://xxxxxxxx
    NSString *type = [attachment objectForKey:@"t"]; // https://developer.apple.com/library/mac/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
    
    if (![urlString isKindOfClass:[NSString class]] || ![type isKindOfClass:[NSString class]])
    {
        return nil; //TODO: Add logs
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (url == nil)
    {
        //TODO: Log
        return nil;
    }
    
    BAERichNotificationAttachment *retVal = [BAERichNotificationAttachment new];
    retVal.url = url;
    retVal.type = type;
    return retVal;
}

- (void)downloadAttachment:(BAERichNotificationAttachment*)attachment completionHandler:(void (^)(NSURL *location, NSString *typeHint, NSError *error))completionHandler
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    if (@available(iOS 13.0, *)) {
        config.allowsConstrainedNetworkAccess = [BAERichNotificationHelper allowInLowDataMode];
    }
    
    config.timeoutIntervalForResource = BA_TIMEOUT_INTERVAL;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    [[session downloadTaskWithURL:attachment.url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completionHandler(location, attachment.type, error);
    }] resume];
}

@end
