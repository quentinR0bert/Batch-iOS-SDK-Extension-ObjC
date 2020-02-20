//
//  BAEDisplayReceiptCacheHelper.h
//  BatchExtension
//
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAEDisplayReceipt.h"
#import "Consts.h"

@interface BAEDisplayReceiptCacheHelper : NSObject

+ (nullable NSString *)sharedGroupId;
+ (nullable NSURL *)sharedDirectory:(NSError * _Nullable * _Nullable)error;
+ (nullable NSUserDefaults *)sharedDefaults;

// MARK: Methods updating cache files
+ (nonnull NSString *)newFilename;
+ (nullable NSData *)readFromFile:(nonnull NSURL *)file error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)writeToFile:(nonnull NSURL *)file data:(nonnull NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)write:(nonnull NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (void)remove:(nonnull NSURL *)file;
+ (nullable NSArray<NSURL *> *)cachedFiles:(NSError * _Nullable * _Nullable)error;

// MARK: Methods reading user defaults
+ (BOOL)isOptOut;

@end
