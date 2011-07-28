//
//  BinaryDownloaderPlugin.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "BinaryDownloaderPlugin.h"
#import "FileDownloadURLConnection.h"
#import "NSMutableArray+QueueAdditions.h"

@implementation DownloadQueueItem

@synthesize uri, filepath, context;

+ (id) newItem:(NSString*)aUri filepath:(NSString*)aFilepath context:(NSString*)aContext
{
	DownloadQueueItem* item = [DownloadQueueItem alloc];
    if (!item) return nil;
	
	item.uri = aUri;
	item.filepath = aFilepath;
	item.context = aContext;
	
    return item;
}

- (void) dealloc 
{
	self.uri = nil;
	self.filepath = nil;
	self.context = nil;
	
    [super dealloc];
}

- (NSString*) JSONValue
{
	return [NSString stringWithFormat:@"{ uri: '%@', filepath: '%@', context: '%@' }",
			self.uri, self.filepath, self.context
			];
}

- (BOOL) isEqual:(id)other 
{
    if (other == self)
        return YES;
    
	if (!other || ![other isKindOfClass:[self class]])
        return NO;
	
	DownloadQueueItem* item = (DownloadQueueItem*)other;
    return [self.uri isEqual:item.uri] && [self.filepath isEqual:item.filepath] && [self.context isEqual:item.context];
}

@end


@implementation BinaryDownloaderPlugin

@synthesize downloadQueue, activeDownloads;

-(PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (BinaryDownloaderPlugin*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
		self.downloadQueue = [[NSMutableArray alloc] init];
        self.activeDownloads = [NSMutableDictionary dictionaryWithCapacity:2];
    }
	return self;
}

- (void) cancel:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 2) {
		return;
	}
	
	NSString* callbackId = [arguments objectAtIndex:0];
	NSString* uri = [arguments objectAtIndex:1];

	FileDownloadURLConnection* conn = [self.activeDownloads objectForKey:uri];
	if (conn != nil) 
	{
		[conn cancel];
		[self.activeDownloads removeObjectForKey:uri];
		
		NSString* successString = [NSString stringWithFormat:@"Download '%@' successfully cancelled.", uri];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:successString];
		[super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
	}
	else if ([self.activeDownloads count] == 0 || conn == nil)
	{
		NSString* errorString = [NSString stringWithFormat:@"Download '%@' not found as an active download.", uri];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}
}

- (void) __downloadItem:(DownloadQueueItem*)queueItem
{
	NSURL* url = [NSURL URLWithString:queueItem.uri];
	NSString* filePath = [NSURL URLWithString:queueItem.filepath];
    
	if (url != nil)
	{
		FileDownloadURLConnection* conn = [[FileDownloadURLConnection alloc] initWithURL:url delegate:self andFilePath:filePath];
		conn.context = queueItem.context;
		[self.activeDownloads setObject:conn forKey:queueItem.uri];
		[conn start];
		[conn release];
	}
}

- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 4) {
		return;
	}
	
	NSString* callbackId = [arguments objectAtIndex:0];
	NSString* uri = [arguments objectAtIndex:1];
	NSString* filepath = [arguments objectAtIndex:2];

	@synchronized(self) 
	{
		DownloadQueueItem* queueItem = [DownloadQueueItem newItem:uri filepath:filepath context:callbackId];
		// check whether queueItem already exists in queue
		NSUInteger index = [self.downloadQueue indexOfObject:queueItem];
		if (index == NSNotFound) {
			[self.downloadQueue enqueue:queueItem];
		}
		[queueItem release];

		if ([self.downloadQueue count] == 1) {
			[self __downloadItem:[self.downloadQueue queueHead]];
		}
	}
}

#pragma mark -
#pragma mark FileDownloadURLConnectionDelegate methods

- (void) connectionDidFail:(FileDownloadURLConnection*)theConnection withError:(NSError*)error
{	
	NSString* urlKey = [theConnection.url description];
	NSDictionary* errorDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:urlKey, [error localizedDescription], nil] 
									   forKeys:[NSArray arrayWithObjects:@"url", @"error", nil]];

	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsDictionary:errorDict];
	[super writeJavascript:[pluginResult toErrorCallbackString:theConnection.context]];
	
	FileDownloadURLConnection* conn = [self.activeDownloads valueForKey:urlKey];
	if (conn != nil) 
	{
		[self.activeDownloads removeObjectForKey:urlKey];
	}
	
	@synchronized(self) 
	{
		if ([self.downloadQueue count] > 0) 
		{
			[self.downloadQueue dequeue]; // dequeue current
			DownloadQueueItem* queueItem = [self.downloadQueue queueHead]; // get next
			if (queueItem != nil) {
				[self __downloadItem:queueItem];
			}
		}
	}
}

- (void) connectionDidFinish:(FileDownloadURLConnection*)theConnection
{	
	NSString* urlKey = [theConnection.url description];
	NSDictionary* successDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:urlKey, theConnection.filePath, @"finished", nil] 
														  forKeys:[NSArray arrayWithObjects:@"url", @"filePath", @"status", nil]];
	
	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsDictionary:successDict];
	[super writeJavascript:[pluginResult toSuccessCallbackString:theConnection.context]];
	
	FileDownloadURLConnection* conn = [self.activeDownloads valueForKey:urlKey];
	if (conn != nil) 
	{
		[self.activeDownloads removeObjectForKey:urlKey];
	}
	
	@synchronized(self) 
	{
		if ([self.downloadQueue count] > 0) 
		{
			[self.downloadQueue dequeue]; // dequeue current
			DownloadQueueItem* queueItem = [self.downloadQueue queueHead]; // get next
			if (queueItem != nil) {
				[self __downloadItem:queueItem];
			}
		}
	}
}

- (void) connectionDownloadProgress:(FileDownloadURLConnection*)theConnection 
						 totalBytes:(u_int64_t)totalBytes 
						   newBytes:(u_int64_t)newBytes
{
	
	NSString* urlKey = [theConnection.url description];
	NSDictionary* successDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:urlKey, theConnection.filePath, @"downloading", theConnection.contentLength, totalBytes, nil] 
															forKeys:[NSArray arrayWithObjects:@"url", @"filePath", @"status", @"contentLength", @"bytesDownloaded", nil]];
	
	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsDictionary:successDict];
	[super writeJavascript:[pluginResult toSuccessCallbackString:theConnection.context]];
}

@end
