//
//  FileDownloadURLConnection.h
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "FileDownloadURLConnection.h"


@implementation FileDownloadURLConnection

@synthesize delegate;
@synthesize receivedData;
@synthesize lastModified, contentLength;
@synthesize connection;
@synthesize url, filePath, fileHandle, context;


- (NSError*) _createNSError:(NSString*)description path:(NSString*)path
{
	NSArray* objArray = [NSArray arrayWithObjects:description, path, nil];
	NSArray* keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, NSFilePathErrorKey, nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
	
	return [[[NSError alloc] initWithDomain:@"FileDownloadUrlConnection" code:0 userInfo:dict] autorelease];	
}

- (void) cancel
{
	[self.connection cancel];
}

/* This method initiates the load request. The connection is asynchronous, 
 and we implement a set of delegate methods that act as callbacks during 
 the load. */

- (id) initWithURL:(NSURL *)theURL delegate:(id<FileDownloadURLConnectionDelegate>)theDelegate andFilePath:(NSString*)theFilePath
{
	if ((self = [super init])) {

		self.delegate = theDelegate;
		self.url = theURL;
		self.filePath = theFilePath;
		
		/* Create the request. This application does not use a NSURLCache 
		 disk or memory cache, so our cache policy is to satisfy the request
		 by loading the data from its source. */
		
		NSURLRequest* theRequest = [NSURLRequest requestWithURL:self.url
													cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
												timeoutInterval:60];
		
		/* create the NSMutableData instance that will hold the received data */
		self.receivedData = [NSMutableData dataWithLength:0];

		/* Create the connection with the request and start loading the
		 data. The connection object is owned both by the creator and the
		 loading system. */
			
		self.connection = [[NSURLConnection alloc] initWithRequest:theRequest 
																	  delegate:self 
															  startImmediately:NO];
		if (self.connection == nil) {
			/* inform the user that the connection failed */
			NSString *message = NSLocalizedString (@"Unable to initiate request.", 
												   @"NSURLConnection initialization method failed.");
			
			NSLog(@"%@", message);
		}
	}

	return self;
}

- (void) start
{
	[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.connection start];
}

- (NSString*) JSONValue
{
	return [NSString stringWithFormat:@"{ url: '%@', filePath: '%@', contentLength: '%@', lastModified: '%@' }",
			[self.url description], self.filePath, self.contentLength, self.lastModified
			];
}

- (void)dealloc
{
	self.receivedData = nil;
	self.lastModified = nil;
	self.url = nil;
	self.delegate = nil;
	self.connection = nil;
	self.filePath = nil;
	self.fileHandle = nil;
	self.context = nil;
	
	[super dealloc];
}


#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection*)theConnection didReceiveResponse:(NSURLResponse *)response
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath] == NO) 
	{
		/* file doesn't exist, so create it */
		[[NSFileManager defaultManager] createFileAtPath:self.filePath 
												contents:self.receivedData 
											  attributes:nil];
		
		self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
	}
	else 
	{
		NSString* message = [NSString stringWithFormat:@"Error: Unable to create file: %@", self.filePath];
		[self.delegate connectionDidFail:self withError:[self _createNSError:message path:self.filePath]];
		[theConnection cancel];
		return;
	}
	
    /* This method is called when the server has determined that it has
	 enough information to create the NSURLResponse. It can be called
	 multiple times, for example in the case of a redirect, so each time
	 we reset the data. */
	
    [self.receivedData setLength:0];
	
	/* Try to retrieve last modified date from HTTP header. If found, format  
	 date so it matches format of cached image file modification date. */
	
	if ([response isKindOfClass:[NSHTTPURLResponse self]]) {
		NSDictionary* headers = [(NSHTTPURLResponse*)response allHeaderFields];
		
		NSString* modified = [headers objectForKey:@"Last-Modified"];
		self.contentLength = [headers objectForKey:@"Content-Length"];
		
		if (modified) {
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			self.lastModified = [dateFormatter dateFromString:modified];
			[dateFormatter release];
		}
		else {
			/* default if last modified date doesn't exist (not an error) */
			self.lastModified = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
		}
	}
}


- (void) connection:(NSURLConnection*)theConnection didReceiveData:(NSData *)data
{
	u_int64_t total = [self.fileHandle seekToEndOfFile];
	u_int64_t new = [data length];
	
	[self.fileHandle writeData:data];
	[self.delegate connectionDownloadProgress:self totalBytes:(total + new) newBytes:new];
}


- (void) connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	[self.delegate connectionDidFail:self withError:error];
	self.delegate = nil;
	self.connection = nil;
	[self.fileHandle closeFile];
}

- (NSCachedURLResponse *) connection:(NSURLConnection*)connection 
				   willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
	/* this application does not use a NSURLCache disk or memory cache */
    return nil;
}


- (void) connectionDidFinishLoading:(NSURLConnection*)aConnection
{
	[self.delegate connectionDidFinish:self];
	self.delegate = nil;
	self.connection = nil;
	[self.fileHandle closeFile];
}


@end
