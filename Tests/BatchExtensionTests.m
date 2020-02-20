//
//  BatchExtensionTests.m
//  BatchExtensionTests
//
//  Copyright © 2020 Batch. All rights reserved.
//

#import <XCTest/XCTest.h>

@import BatchExtension;
#import "BAEDisplayReceipt.h"

@interface BAERichNotificationAttachment : NSObject

@property (nonnull) NSURL *url;
@property (nonnull) NSString *type;

@end

@interface BAERichNotificationHelper()
- (BAERichNotificationAttachment*)attachmentForPayload:(NSDictionary*)userInfo;
@end

@interface BAEDisplayReceiptHelper()
- (nullable BAEDisplayReceipt *)displayReceiptForPayload:(NSDictionary *)userInfo;
@end

@interface BatchExtensionTests : XCTestCase

@end

@implementation BatchExtensionTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testURLExtraction {
    NSString *validURL = @"https://batch.com/foo.png";
    NSString *validType = @"image/png";
    
    NSDictionary *validPayload = @{
        @"com.batch": @{@"at": @{@"u": validURL, @"t": validType}}
    };
    
    NSDictionary *invalidURLPayload = @{
        @"com.batch": @{@"u": @"foobar$", @"t": validType}
    };
    
    NSArray<NSDictionary *> *missingPayloads = @[
        @{},
        @{@"foo": @"bar"},
        @{@"com.batch":@{@"foo": @"bar"}},
        @{@"com.batch":@{@"at": @{}}},
        @{@"com.batch":@{@"at": @{@"foo": @"bar"}}},
        @{@"com.batch":@{@"at": @{@"u": @"https://batch.com/favicon.ico"}}},
        @{@"com.batch":@{@"at": @{@"t": @"image/jpeg"}}}
    ];
    
    BAERichNotificationHelper *helper = [BAERichNotificationHelper new];
    BAERichNotificationAttachment *attachment = [helper attachmentForPayload:validPayload];
    
    XCTAssert([[attachment url] isEqual:[NSURL URLWithString:validURL]]);
    XCTAssert([[attachment type] isEqual:validType]);
    XCTAssertNil([helper attachmentForPayload:invalidURLPayload]);
    
    for (NSDictionary *payload in missingPayloads) {
        XCTAssertNil([helper attachmentForPayload:payload]);
    }
}

- (void)testDisplayReceiptExtraction {
    BAEDisplayReceiptHelper *helper = [BAEDisplayReceiptHelper new];
    
    NSDictionary *invalidPayload = @{};
    BAEDisplayReceipt *invalidReceipt = [helper displayReceiptForPayload:invalidPayload];
    XCTAssertNil(invalidReceipt);
    
    NSDictionary *validPayload = @{
        @"com.batch": @{@"r":@{@"m":@1}}
    };
    BAEDisplayReceipt *receipt = [helper displayReceiptForPayload:validPayload];
    XCTAssertNotNil(receipt);
    XCTAssertFalse([receipt replay]);
    XCTAssertEqual([receipt sendAttempt], 0);
    XCTAssertTrue([receipt od] == nil || [[receipt od] count] == 0);
    XCTAssertTrue([receipt ed] == nil || [[receipt ed] count] == 0);
    
    NSDictionary *validPayload2 = @{
        @"com.batch": @{@"r":@{@"m":@2}}
    };
    
    BAEDisplayReceipt *receipt2 = [helper displayReceiptForPayload:validPayload2];
    XCTAssertNotNil(receipt2);
    XCTAssertFalse([receipt2 replay]);
    XCTAssertEqual([receipt2 sendAttempt], 0);
    XCTAssertTrue([receipt2 od] == nil || [[receipt2 od] count] == 0);
    XCTAssertTrue([receipt2 ed] == nil || [[receipt2 ed] count] == 0);
}

- (void)testDisplayReceiptOpenDataExtraction {
    
    BAEDisplayReceiptHelper *helper = [BAEDisplayReceiptHelper new];
    
    NSDictionary *od = @{
        @"sef": @"toto", @"bool": @true, @"hip": @"hop"
    };
    
    NSDictionary *validPayload = @{
        @"com.batch": @{@"r":@{@"m":@1}, @"od": od}
    };
    
    BAEDisplayReceipt *receipt = [helper displayReceiptForPayload:validPayload];
    XCTAssertNotNil(receipt);
    XCTAssertFalse([receipt replay]);
    XCTAssertEqual([receipt sendAttempt], 0);
    XCTAssertTrue([[receipt od] isEqualToDictionary:od]);
    XCTAssertTrue([receipt ed] == nil || [[receipt ed] count] == 0);
}

- (void)testDisplayReceiptEventDataExtraction {

    BAEDisplayReceiptHelper *helper = [BAEDisplayReceiptHelper new];
    
    NSDictionary *validPayload = @{
        @"com.batch": @{@"r":@{@"m":@1}, @"i": @"test-i", @"ex": @"test-ex", @"va": @"test-va"}
    };
    
    NSDictionary *ed = @{
        @"i": @"test-i", @"ex": @"test-ex", @"va": @"test-va"
    };
    
    BAEDisplayReceipt *receipt = [helper displayReceiptForPayload:validPayload];
    XCTAssertNotNil(receipt);
    XCTAssertFalse([receipt replay]);
    XCTAssertEqual([receipt sendAttempt], 0);
    XCTAssertTrue([[receipt ed] isEqualToDictionary:ed]);
    XCTAssertTrue([receipt od] == nil || [[receipt od] count] == 0);
}

- (void)testReceiptPackUnpack {
    
    NSArray *nestedList = @[
        @false,
        @"test",
        @25.69745,
        @654,
        [NSNull null]
    ];
    
    NSDictionary *nestedOd = @{
        @"bool": @false,
        @"int": @654,
        @"float": @64.285,
        @"list": nestedList,
        @"null": [NSNull null]
    };
    
    NSDictionary *od = @{
        @"n": @"je-suis-un-n",
        @"t": @"je-suis-un-t",
        @"ak": @"je-suis-un-ak",
        @"di": @"je-suis-un-di",
        @"null": [NSNull null],
        @"map": nestedOd,
        @"list": nestedList,
        @"bool_true": @true,
        @"bool_false": @false
    };
    
    NSDictionary *ed = @{
        @"i": @"je-suis-un-i",
        @"e": @"je-suis-un-e",
        @"v": @"je-suis-un-va"
    };
    
    BAEDisplayReceipt *receipt = [[BAEDisplayReceipt alloc] initWithTimestamp:123456 replay:false sendAttempt:19 openData:od eventData:ed];
    XCTAssertNotNil(receipt);
    NSError *error = nil;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);
    
    BAEDisplayReceipt *unpackReceipt = [BAEDisplayReceipt unpack:packedData error:&error];
    XCTAssertNotNil(unpackReceipt);
    XCTAssertNil(error);
    
    XCTAssertEqual([unpackReceipt timestamp], 123456);
    XCTAssertEqual([unpackReceipt replay], false);
    XCTAssertEqual([unpackReceipt sendAttempt], 19);
    XCTAssert([od isEqualToDictionary:[unpackReceipt od]]);
    XCTAssert([ed isEqualToDictionary:[unpackReceipt ed]]);
}

-(void)testReceiptPackEmptyMap {
    BAEDisplayReceipt *receipt = [[BAEDisplayReceipt alloc] initWithTimestamp:65481651581 replay:true sendAttempt:6585 openData:@{} eventData:@{}];
    XCTAssertNotNil(receipt);
    NSError *error = nil;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);
    
    XCTAssert([@"cf0000000f3f02b57dc3cd19b9c0c0" isEqualToString:[self hexStringFromData:packedData]]);
}

- (void)testReceiptPackNil {
    BAEDisplayReceipt *receipt = [[BAEDisplayReceipt alloc] initWithTimestamp:65481651581 replay:true sendAttempt:6585 openData:nil eventData:nil];
    XCTAssertNotNil(receipt);
    NSError *error = nil;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);
    
    XCTAssert([@"cf0000000f3f02b57dc3cd19b9c0c0" isEqualToString:[self hexStringFromData:packedData]]);
}

- (void)testReceiptUnpackNil {
    
    NSData *packedData = [self dataFromHexString:@"cf0000000f3f02b57dc3cd19b9c0c0"];
    NSError *error = nil;
    BAEDisplayReceipt *unpackReceipt = [BAEDisplayReceipt unpack:packedData error:&error];
    XCTAssertNotNil(unpackReceipt);
    XCTAssertNil(error);
    
    XCTAssertNil([unpackReceipt od]);
    XCTAssertNil([unpackReceipt ed]);
}

// MARK: Utils methods

- (NSData *)dataFromHexString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    unsigned long length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

- (NSString *)hexStringFromData:(NSData *)data {

    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return [NSString string];
    }

    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}

@end
