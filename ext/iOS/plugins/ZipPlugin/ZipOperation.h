//
//  ZipOperation.h
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZipArchive.h"

@interface ZipResult : NSObject {
	NSString* source;
	NSString* target;
	NSString* context;
	BOOL zip;
	BOOL ok;
}

@property(copy) NSString* source;
@property(copy) NSString* target;
@property(copy) NSString* context;
@property(assign) BOOL zip;
@property(assign) BOOL ok;

+ (id) newResult:(BOOL)aZip ok:(BOOL)aOk source:(NSString*)aSource target:(NSString*)aTarget context:(NSString*)context;


@end

@interface ZipProgress : NSObject {
	NSString* source;
	NSString* filename;
	NSString* context;
	BOOL zip;
	uint64_t entryNumber;
	uint64_t entryTotal;
}

@property(copy) NSString* source;
@property(copy) NSString* filename;
@property(copy) NSString* context;
@property(assign) BOOL zip;
@property(assign) uint64_t entryNumber;
@property(assign) uint64_t entryTotal;


+ (id) newProgress:(BOOL)aEncrypt source:(NSString*)aSource filename:(NSString*)aFilename context:(NSString*)aContext
		 entryNumber:(uint64_t)entryNumber entryTotal:(uint64_t)entryTotal;

@end


@protocol ZipOperationDelegate<NSObject>

- (void) zipResult:(ZipResult*)result;
- (void) zipProgress:(ZipProgress*)progress;

@end

@interface ZipOperation : NSOperation <ZipArchiveDelegate> {
	NSString* source;
	NSString* target;
	NSString* context;
	BOOL zip;
	NSObject<ZipOperationDelegate>* delegate;
}

@property(copy) NSString* source;
@property(copy) NSString* target;
@property(copy) NSString* context;
@property(assign) BOOL zip;
@property(assign) NSObject<ZipOperationDelegate>* delegate;

- (id)initAsDeflate:(BOOL)zip withSource:(NSString*)source target:(NSString*)target andContext:(NSString*)context;

@end
