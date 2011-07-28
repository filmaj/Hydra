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

@property (nonatomic, retain) NSURLCredential* credential;

+ (id) newItem:(NSString*)aUri withFilepath:(NSString*)aFilepath context:(NSString*)aContext andCredential:(NSURLCredential*)aCredential;
- (NSString*) JSONValue;
- (BOOL) isEqual:(id)other;


@end

@interface BinaryDownloaderPlugin : PGPlugin < FileDownloadURLConnectionDelegate > {
}

@property (nonatomic, retain)	NSMutableArray* downloadQueue;
@property (nonatomic, retain)	NSMutableDictionary* activeDownloads;

- (void) cancel:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
