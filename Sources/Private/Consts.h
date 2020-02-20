//
//  Consts.h
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

#ifndef Consts_h
#define Consts_h

// Timeout for network call
#define BA_TIMEOUT_INTERVAL 20 // 20s

// Rich notification
#define BA_ATTACHMENT_IDENTIFIER @"batch_rich_attachment"

// Display receipts
#define BA_RECEIPT_CACHE_DIRECTORY @"com.batch.displayreceipts"
#define BA_RECEIPT_CACHE_FILE_FORMAT @"%@.bin"
#define BA_RECEIPT_MAX_CACHE_FILE 5
#define BA_RECEIPT_MAX_CACHE_AGE 2592000.0 // 30 days in seconds
#define BA_RECEIPT_HEADER_EXT_VERSION @"x-batch-ext-version"
#define BA_RECEIPT_HEADER_SCHEMA_VERSION @"x-batch-protocol-version"
#define BA_RECEIPT_SCHEMA_VERSION @"1.0.0"

#endif /* Consts_h */
