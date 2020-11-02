//
//  BAEDisplayReceipt.m
//  BatchExtension
//
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import "BAEDisplayReceipt.h"

@implementation BAEDisplayReceipt

- (id)initWithTimestamp:(unsigned long long)timestamp
                replay:(BOOL)replay
           sendAttempt:(unsigned int)sendAttempt
              openData:(NSDictionary *)od
             eventData:(NSDictionary *)ed
{
     self = [super init];
     if (self) {
         _timestamp = timestamp;
         _replay = replay;
         _sendAttempt = sendAttempt;
         _od = od;
         _ed = ed;
     }
     return self;
}

- (BOOL)packToWriter:(nonnull BATMessagePackWriter *)writer error:(NSError **)error
{
    NSError *writerError;
    
    [writer writeUnsignedInt64:_timestamp];
    [writer writeBool:_replay];
    [writer writeUnsignedInt:_sendAttempt];
    if ([_od count] > 0) {
        [writer writeDictionary:_od error:&writerError];
        if (writerError != nil) {
            if (error != nil) {
                *error = writerError;
            }
            return false;
        }
    } else {
        [writer writeNil];
    }
    
    if ([_ed count] > 0) {
        [writer writeDictionary:_ed error:&writerError];
        if (writerError != nil) {
            if (error != nil) {
                *error = writerError;
            }
            return false;
        }
    } else {
        [writer writeNil];
    }

    return true;
}

- (nullable NSData *)pack:(NSError * _Nullable * _Nullable)error
{
    BATMessagePackWriter *writer = [BATMessagePackWriter new];
    if ([self packToWriter:writer error:error]) {
        return writer.data;
    }
    return nil;
}

+ (nullable instancetype)unpack:(nonnull NSData *)data error:(NSError **)error
{
    NSError *readerError;
    
    BATMessagePackReader *reader = [[BATMessagePackReader alloc] initWithData:data];
    NSNumber *timestamp = [reader readIntegerAllowingNil:false error:&readerError];
    if (readerError != nil) {
        if (error != nil) {
            *error = readerError;
        }
        return nil;
    }
    
    BOOL replay = [[reader readBoolAllowingNil:false error:&readerError] boolValue];
    if (readerError != nil) {
        if (error != nil) {
            *error = readerError;
        }
        return nil;
    }
    
    NSNumber *sendAttempt = [reader readIntegerAllowingNil:false error:&readerError];
    if (readerError != nil) {
        if (error != nil) {
            *error = readerError;
        }
        return nil;
    }
    
    NSDictionary *od = [reader readDictionaryAllowingNil:true error:&readerError];
    if (readerError != nil) {
        if (error != nil) {
            *error = readerError;
        }
        return nil;
    }
    
    NSDictionary *ed = [reader readDictionaryAllowingNil:true error:&readerError];
    if (readerError != nil) {
        if (error != nil) {
            *error = readerError;
        }
        return nil;
    }
    
    return [[BAEDisplayReceipt alloc] initWithTimestamp:[timestamp longLongValue] replay:replay sendAttempt:[sendAttempt intValue] openData:od eventData:ed];
}

@end
