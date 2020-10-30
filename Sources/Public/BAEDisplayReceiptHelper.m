//
//  BAEDisplayReceiptHelper.m
//  BatchExtension
//
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import "BAEDisplayReceiptHelper.h"
#import "BAEDisplayReceiptCacheHelper.h"
#import "BAEDisplayReceipt.h"
#import "Consts.h"

#define ERROR_DOMAIN @"com.batch.extension.displayreceipthelper"

@implementation BAEDisplayReceiptHelper

- (void)processDisplayReceiptForContent:(UNNotificationContent*)content completionHandler:(void (^)(UNNotificationContent* _Nullable result, NSError* _Nullable error))completionHandler
{
    if (content == nil)
    {
        completionHandler(nil, [NSError errorWithDomain:ERROR_DOMAIN
                                                   code:-1
                                               userInfo:@{NSLocalizedDescriptionKey: @"No source notification content was provided"}]);
    }

    BAEDisplayReceipt *receipt = [self displayReceiptForPayload:content.userInfo];
    if (receipt != nil) {
        NSError *error = [self save:receipt];
        if (error != nil) {
            completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                           code:-2
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Could not pack or save receipt",
                                                                  NSUnderlyingErrorKey: error}]);
            return;
        }
        
        [self send:^(NSError *error) {
            if (error) {
                completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                           code:-3
                                                       userInfo:@{NSLocalizedDescriptionKey: @"An error occurred while send display receipt",
                                                                  NSUnderlyingErrorKey: error}]);
                return;
            }
        }];
        completionHandler(content, nil);
    } else {
        completionHandler(content, [NSError errorWithDomain:ERROR_DOMAIN
                                                       code:-4
                                                   userInfo:@{NSLocalizedDescriptionKey: @"No or invalid receipt data found in the notification content"}]);
    }
}

- (void)didReceiveNotificationRequest:(nonnull UNNotificationRequest *)request
{
    if ([BAEDisplayReceiptCacheHelper isOptOut]) {
        NSLog(@"Batch - SDK is opt-out, skipping display receipts...");
        return;
    }
    
    [self processDisplayReceiptForContent:request.content completionHandler:^(UNNotificationContent * _Nonnull result, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Batch - An error occurred while processing display receipts: %@", error);
        }
    }];
}

- (void)serviceExtensionTimeWillExpire
{
    // Nothing here yet. We might use this in the future.
}

//MARK: PRIVATE METHODS

- (nullable NSDictionary *)eventData:(NSDictionary *)batchPayload
{
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    id i = [batchPayload objectForKey:@"i"];
    if (i != nil) {
        [eventData setObject:i forKey:@"i"];
    }
    
    id ex = [batchPayload objectForKey:@"ex"];
    if (ex != nil) {
        [eventData setObject:ex forKey:@"ex"];
    }
    
    id va = [batchPayload objectForKey:@"va"];
    if (va != nil) {
        [eventData setObject:va forKey:@"va"];
    }

    return eventData;
}

- (nullable BAEDisplayReceipt *)displayReceiptForPayload:(NSDictionary *)userInfo
{
    if (userInfo == nil) {
        return nil;
    }
    
    NSDictionary *batchPayload = [userInfo objectForKey:@"com.batch"];
    if (![batchPayload isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *receiptPayload = [batchPayload objectForKey:@"r"];
    if (![receiptPayload isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    int receiptMode = [[receiptPayload objectForKey:@"m"] intValue];
    if (receiptMode == 1 || receiptMode == 2) {
        unsigned long long currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSDictionary *openData = [batchPayload objectForKey:@"od"];
        if (![openData isKindOfClass:[NSDictionary class]]) {
            openData = nil;
        }
        NSDictionary *eventData = [self eventData:batchPayload];
        return [[BAEDisplayReceipt alloc] initWithTimestamp:currentTimestamp
                                                    replay:false
                                               sendAttempt:0
                                                  openData:openData
                                                 eventData:eventData];
    }
    return nil;
}

- (void)send:(void (^)(NSError *error))completionHandler
{
    NSError *error;
    NSArray<NSURL *>* files = [BAEDisplayReceiptCacheHelper cachedFiles:&error];
    if (error != nil) {
        completionHandler(error);
        return;
    }
    
    if (files != nil) {
        NSMutableArray<BAEDisplayReceipt *>* receipts = [NSMutableArray array];
        NSMutableArray<NSURL *> __block *filesToDelete = [NSMutableArray array];
        for (NSURL *file in files) {
            NSData *data = [BAEDisplayReceiptCacheHelper readFromFile:file error:nil];
            if (data != nil) {
                BAEDisplayReceipt *receipt = [BAEDisplayReceipt unpack:data error:nil];
                if (receipt != nil) {
                    // Update payload before send
                    [receipt setSendAttempt:[receipt sendAttempt] + 1];
                    [receipt setReplay:false];
                    
                    // Resave the receipt
                    NSData *updatedData = [receipt pack:nil];
                    if (updatedData != nil && [BAEDisplayReceiptCacheHelper writeToFile:file data:updatedData error:nil]) {
                        [receipts addObject:receipt];
                        [filesToDelete addObject:file];
                    }
                }
            }
        }
        
        if ([receipts count] <= 0) {
            // Nothing to send
            return;
        }
        
        BATMessagePackWriter *writer = [[BATMessagePackWriter alloc] init];
        [writer writeArraySize:[receipts count] error:nil];
        
        for (BAEDisplayReceipt *receipt in receipts) {
            [receipt packToWriter:writer error:nil];
        }
        
        NSURLSessionConfiguration *urlSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [urlSessionConfiguration setTimeoutIntervalForResource:BA_TIMEOUT_INTERVAL];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:urlSessionConfiguration];
        
        // Setup request.
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://drws.batch.com/i/%@", BA_RECEIPT_SCHEMA_VERSION]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request addValue:BA_RECEIPT_SCHEMA_VERSION forHTTPHeaderField:BA_RECEIPT_HEADER_SCHEMA_VERSION];
        [request addValue:@"1.0.0-objc" forHTTPHeaderField:BA_RECEIPT_HEADER_EXT_VERSION]; // TODO ext version
        
        NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:writer.data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] <= 399) {
                    for (NSURL *file in filesToDelete) {
                        [BAEDisplayReceiptCacheHelper remove:file];
                    }
                }
            }
            completionHandler(error);
        }];
        [task resume];
        [session finishTasksAndInvalidate];
    } else {
        completionHandler(nil);
    }
}

- (nullable NSError *)save:(nonnull BAEDisplayReceipt *)receipt
{
    NSError *error = nil;
    NSData *payload = [receipt pack:&error];
    if (payload != nil) {
        if ([BAEDisplayReceiptCacheHelper write:payload error:&error]) {
            return nil;
        }
    }
    return error;
}

@end
