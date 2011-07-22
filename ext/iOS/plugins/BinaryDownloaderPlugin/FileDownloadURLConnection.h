//
//  FileDownloadURLConnection.h
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import <UIKit/UIKit.h>

@protocol FileDownloadURLConnectionDelegate;

@interface FileDownloadURLConnection : NSObject 
{
	id <FileDownloadURLConnectionDelegate> delegate;
	NSMutableData* receivedData;
	NSDate* lastModified;
	NSString* contentLength;
	
	NSURLConnection* connection;
	NSURL* url;
	NSString* filePath;
	NSFileHandle* fileHandle;
	NSString* context;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) NSDate* lastModified;
@property (nonatomic, copy) NSString* contentLength;

@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, copy)   NSString* filePath;
@property (nonatomic, retain) NSFileHandle* fileHandle;
@property (nonatomic, copy)   NSString* context;

- (id) initWithURL:(NSURL *)theURL delegate:(id<FileDownloadURLConnectionDelegate>)theDelegate andFilePath:(NSString*)filePath;
- (void) cancel;
- (void) start;

- (NSString*) JSONValue;

@end


@protocol FileDownloadURLConnectionDelegate<NSObject>

- (void) connectionDidFail:(FileDownloadURLConnection*)theConnection withError:(NSError*)error;
- (void) connectionDidFinish:(FileDownloadURLConnection*)theConnection;
- (void) connectionDownloadProgress:(FileDownloadURLConnection*)theConnection totalBytes:(u_int64_t)totalBytes newBytes:(u_int64_t)newBytes;

@end
