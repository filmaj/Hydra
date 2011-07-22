//
//  BinaryDownloaderPlugin.h
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import <Foundation/Foundation.h>
#import "FileDownloadURLConnection.h"

#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/PGPlugin.h>
#else
    #import "PGPlugin.h"
#endif

@interface DownloadQueueItem : NSObject {
}

@property (nonatomic, copy) NSString* uri;
@property (nonatomic, copy) NSString* filepath;
@property (nonatomic, copy) NSString* context;

+ (id) newItem:(NSString*)aUri filepath:(NSString*)aFilepath context:(NSString*)aContext;
- (NSString*) JSONValue;
- (BOOL) isEqual:(id)other;


@end

@interface BinaryDownloaderPlugin : PGPlugin < FileDownloadURLConnectionDelegate > {
}

@property (nonatomic, retain)	NSMutableArray* downloadQueue;
@property (nonatomic, retain)	NSMutableDictionary* activeDownloads;
@property (nonatomic, retain)	NSOperationQueue* operationQueue;

- (void) cancel:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
