//
//  BAEDisplayReceiptCacheHelper.m
//  BatchExtension
//
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import "BAEDisplayReceiptCacheHelper.h"

#define ERROR_DOMAIN @"com.batch.extension.displayreceiptcachehelper"

static NSFileCoordinator *coordinator = nil;

@implementation BAEDisplayReceiptCacheHelper

+ (void)initialize {
    coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
}

+ (nullable NSString *)sharedGroupId
{
    NSString *groupIdOverride = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BATCH_APP_GROUP_ID"];
    if (groupIdOverride != nil && [groupIdOverride isKindOfClass:[NSString class]] && [groupIdOverride length] > 0) {
        return groupIdOverride;
    }
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier != nil && [bundleIdentifier isKindOfClass:[NSString class]] && [bundleIdentifier length] > 0) {
        return [[@"group." stringByAppendingString:bundleIdentifier] stringByAppendingString:@".batch"];
    }
    
    return nil;
}

+ (nullable NSURL *)sharedDirectory:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *sharedGroupDir = [fm containerURLForSecurityApplicationGroupIdentifier:[self sharedGroupId]];
    NSURL *cacheDir = [sharedGroupDir URLByAppendingPathComponent:BA_RECEIPT_CACHE_DIRECTORY isDirectory:true];
    if (cacheDir == nil) {
        *error = [NSError errorWithDomain:ERROR_DOMAIN
            code:-1
        userInfo:@{NSLocalizedDescriptionKey: @"Could not get shared cache directory"}];
        return nil;
    }
    
    if ([fm createDirectoryAtURL:cacheDir withIntermediateDirectories:true attributes:nil error:error] == false) {
        return nil;
    }
    return cacheDir;
}

+ (nullable NSUserDefaults *)sharedDefaults
{
    NSString *groupId = [self sharedGroupId];
    if (groupId != nil) {
        return [[NSUserDefaults alloc] initWithSuiteName:groupId];
    }
    return nil;
}

// MARK: Methods updating cache files

+ (nonnull NSString *)newFilename
{
    return [NSString stringWithFormat:BA_RECEIPT_CACHE_FILE_FORMAT, [[NSUUID UUID] UUIDString]];
}

+ (nullable NSData *)readFromFile:(nonnull NSURL *)file error:(NSError * _Nullable * _Nullable)error
{
    NSError *readError;
    __block NSData *data;
    [coordinator coordinateReadingItemAtURL:file options:NSFileCoordinatorReadingWithoutChanges error:&readError byAccessor:^(NSURL * _Nonnull newURL) {
        data = [NSData dataWithContentsOfURL:newURL];
    }];
    
    if (readError != nil) {
        if (error != nil) {
            *error = readError;
        }
        return nil;
    }
    
    return data;
}

+ (BOOL)writeToFile:(nonnull NSURL *)file data:(nonnull NSData *)data error:(NSError * _Nullable * _Nullable)error
{
    NSError *coordError;
    __block NSError *writeError;
    [coordinator coordinateWritingItemAtURL:file options:NSFileCoordinatorWritingForReplacing error:&coordError byAccessor:^(NSURL * _Nonnull newURL) {
        [data writeToURL:newURL options:NSDataWritingAtomic error:&writeError];
    }];
    
    if (coordError != nil) {
        if (error != nil) {
            *error = coordError;
        }
       return false;
    }
    
    if (writeError != nil) {
        if (error != nil) {
            *error = writeError;
        }
        return false;
    }
    return true;
}

+ (BOOL)write:(nonnull NSData *)data error:(NSError * _Nullable * _Nullable)error
{
    NSURL *cacheDir = [self sharedDirectory:error];
    if (cacheDir == nil) {
        return false;
    }
    
    NSURL *cacheFile = [cacheDir URLByAppendingPathComponent:[self newFilename]];
    return [self writeToFile:cacheFile data:data error:error];
}

+ (void)remove:(nonnull NSURL *)file
{
    [coordinator coordinateWritingItemAtURL:file options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL * _Nonnull newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
    }];
}

+ (nullable NSArray<NSURL *> *)cachedFiles:(NSError * _Nullable * _Nullable)error
{
    NSURL *cacheDir = [self sharedDirectory:error];
    if (cacheDir == nil) {
        return nil;
    }
    
    NSError *readError;
    NSArray<NSURL *> *files = [[NSFileManager defaultManager]
                              contentsOfDirectoryAtURL:cacheDir
                              includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLCreationDateKey, NSURLIsReadableKey]
                              options:NSDirectoryEnumerationSkipsHiddenFiles
                              error:&readError];
    
    if (readError != nil || files == nil) {
        if (error != nil) {
            *error = readError;
        }
        return nil;
    }
    
    NSMutableDictionary *cachedReceipts = [NSMutableDictionary dictionary];
    for (NSURL *file in files) {
        readError = nil;
        NSDictionary<NSURLResourceKey, id> *fileAttributes = [file resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLCreationDateKey, NSURLIsReadableKey] error:&readError];
        if (fileAttributes != nil &&
            [[fileAttributes objectForKey:NSURLIsRegularFileKey] boolValue] == true &&
            [[fileAttributes objectForKey:NSURLIsReadableKey] boolValue] == true) {
            
            NSDate *creationDate = [fileAttributes objectForKey:NSURLCreationDateKey];
            if (creationDate != nil && creationDate.timeIntervalSinceNow > BA_RECEIPT_MAX_CACHE_AGE * -1.0) {
                [cachedReceipts setObject:creationDate forKey:file];
            } else {
                // File too old, deleting
                [self remove:file];
            }
            
        }
    }
    
    if ([cachedReceipts count] <= 0) {
        return nil;
    }
    
    [cachedReceipts keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return obj1 > obj2;
    }];
    
    NSArray<NSURL *> *tmp = [cachedReceipts allKeys];
    return [tmp subarrayWithRange:NSMakeRange(0, MIN(BA_RECEIPT_MAX_CACHE_FILE, tmp.count))];
}

// MARK: Methods reading user defaults

+ (BOOL)isOptOut
{
    if ([[self sharedDefaults] objectForKey:@"batch_shared_optout"] == nil) {
        // Key is missing, we don't send display receipt
        return true;
    }
    
    return [[self sharedDefaults] boolForKey:@"batch_shared_optout"];
}

@end
