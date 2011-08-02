//
//  AppLoader.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "AppLoader.h"
#import "PhoneGapDelegate.h"
#import "BinaryDownloader.h"
#import	"FileDownloadURLConnection.h"
#import "ZipUtil.h"
#import "UIWebView+PGAdditions.h"

#define HYDRA_DOWNLOADS_FOLDER	@"HydraDownloads"
#define HYDRA_APPS_FOLDER		@"HydraApps"
#define BINARY_DOWNLOAD_PLUGIN	@"com.nitobi.BinaryDownloader"
#define ZIP_UTIL_PLUGIN			@"com.nitobi.ZipUtil"


@interface NSObject (AppLoader_PrivateMethods)

- (NSString*) __makeLibrarySubfolder:(NSString*)foldername;
- (BOOL) __clearLibrarySubfolder:(NSString*)foldername;

- (BOOL) removeNavigationBar;
- (BOOL) createNavigationBar;

@end


@implementation AppLoader

@synthesize downloadsFolder, appsFolder, navigationBar;


- (PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (AppLoader*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
		self.downloadsFolder = [self __makeLibrarySubfolder:HYDRA_DOWNLOADS_FOLDER];
		self.appsFolder = [self __makeLibrarySubfolder:HYDRA_APPS_FOLDER];
    }
	return self;
}

- (NSString*) appFilePath:(NSString*)appId
{
	return [NSString stringWithFormat:@"%@/%@", self.appsFolder, appId];
}

- (NSString*) downloadFilePath:(NSString*)appId
{
	return [NSString stringWithFormat:@"%@/%@", self.downloadsFolder, appId];
}

- (NSString*) appUrl:(NSString*)appId
{
	return [NSString stringWithFormat:@"file://%@/index.html", [self appFilePath:appId]];
}

- (NSURL*) homeUrl
{
	NSString* homeFilePath = [PhoneGapDelegate pathForResource:[PhoneGapDelegate startPage]];
	return [NSURL fileURLWithPath:homeFilePath];
}

// this is triggered by the navigation bar back button
- (void) goBack
{
	[self removeNavigationBar];
	
	NSURLRequest* homeRequest = [NSURLRequest requestWithURL:[self homeUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
	[self.webView loadRequest:homeRequest];
}

#pragma mark -
#pragma mark NavigationBar

- (BOOL) removeNavigationBar
{
	if (!self.navigationBar) {
		return NO;
	}
	
	[self.webView pg_removeSiblingView:self.navigationBar withAnimation:NO];
	[self.webView pg_relayout:NO];
	
	self.navigationBar = nil;
	
	return YES;
}

- (BOOL) createNavigationBar
{
	if (self.navigationBar) {
		return NO;
	}
	
    CGFloat height   = 45.0f;
    UIBarStyle style = UIBarStyleBlackOpaque;
	
    CGRect toolBarBounds = self.webView.bounds;
	toolBarBounds.size.height = height;
	
    self.navigationBar = [[UINavigationBar alloc] init];
    [self.navigationBar sizeToFit];
    [self.navigationBar pushNavigationItem:[[UINavigationItem alloc] initWithTitle:@""] animated:NO];
    self.navigationBar.autoresizesSubviews    = YES;
    self.navigationBar.userInteractionEnabled = YES;
    self.navigationBar.barStyle               = style;
	
	[self.webView pg_addSiblingView:self.navigationBar withPosition:PGLayoutPositionTop withAnimation:NO];
	
	return YES;
}

#pragma mark -
#pragma mark PhoneGap commands

- (void) load:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* callbackId = [arguments pop];
	VERIFY_ARGUMENTS(arguments, 1, callbackId)
	
    NSString* appId = [arguments objectAtIndex:0];
	
	// ///////////////////////////////////////////	
    
	PluginResult* pluginResult = nil;
	NSString* appFilePath = [self appFilePath:appId];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:appFilePath]) 
	{
		if ([self createNavigationBar]) {
			UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back") style:UIBarButtonItemStyleBordered 
												   target:self action:@selector(goBack)];
			self.navigationBar.topItem.leftBarButtonItem = item;

			[item release];
		}
		pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:[self appUrl:appId]];
		[super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
	} 
	else 
	{
		NSString* errorString = [NSString stringWithFormat:@"Hydra app not found: %@", appFilePath];
		pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}	
}

- (void) fetch:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* callbackId = [arguments pop];
	VERIFY_ARGUMENTS(arguments, 2, callbackId)
    
    NSString* appId = [arguments objectAtIndex:0];
    NSString* uri = [arguments objectAtIndex:1];
	
	int argc = [arguments count];
    NSString* username = argc > 2? [arguments objectAtIndex:2] : nil;
    NSString* password = argc > 3? [arguments objectAtIndex:3] : nil;
	
	// ///////////////////////////////////////////	
    
	NSURLCredential* credential = nil;
	NSString* downloadFilePath = [self downloadFilePath:appId];
	
	if (username !=nil && password != nil) {
		credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceForSession];
	}
	
	BinaryDownloader* bdPlugin = [[self appDelegate] getCommandInstance:BINARY_DOWNLOAD_PLUGIN];
	if (bdPlugin != nil)
	{
		NSDictionary* context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:appId, uri, callbackId, downloadFilePath, nil] 
															forKeys:[NSArray arrayWithObjects:@"appId", @"uri", @"callbackId", @"filePath", nil]];
		DownloadQueueItem* queueItem = [DownloadQueueItem newItem:uri withFilepath:downloadFilePath context:context andCredential:credential];
		[bdPlugin download:queueItem delegate:self];
	}
	else 
	{
		NSString* errorString = [NSString stringWithFormat:@"Plugin '%@' not found.", BINARY_DOWNLOAD_PLUGIN];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}
}

- (void) remove:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* callbackId = [arguments pop];
	VERIFY_ARGUMENTS(arguments, 1, callbackId)
    
    NSString* appId = [arguments objectAtIndex:0];
	
	// ///////////////////////////////////////////
    
	NSString* appFilePath = [self appFilePath:appId];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	PluginResult* pluginResult = nil;
	NSError* error = nil;
	
	if ([fileManager fileExistsAtPath:appFilePath]) 
	{
		[fileManager removeItemAtPath:appFilePath error:&error];
 		if (error != nil) {
			NSString* errorString = [NSString stringWithFormat:@"File removal error: %@", [error localizedDescription]];
			pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
			[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
		}
	} 
	else 
	{
		NSString* errorString = [NSString stringWithFormat:@"Hydra app not found: %@", appFilePath];
		pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}	
}


#pragma mark -
#pragma mark FileDownloadURLConnectionDelegate methods

- (void) connectionDidFail:(FileDownloadURLConnection*)theConnection withError:(NSError*)error
{	
	NSString* callbackId = [theConnection.context objectForKey:@"callbackId"];
	NSString* urlKey = [theConnection.url description];
	
	BinaryDownloader* bdPlugin = [[self appDelegate] getCommandInstance:BINARY_DOWNLOAD_PLUGIN];
	if (bdPlugin != nil) {
		[bdPlugin next:urlKey delegate:self];
	} else {
		NSString* errorString = [NSString stringWithFormat:@"Plugin '%@' not found.", BINARY_DOWNLOAD_PLUGIN];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}		
	
	NSString* errorString = [NSString stringWithFormat:@"Failed to download '%@', error: %@", urlKey, [error localizedDescription]];
	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
	[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
}

- (void) connectionDidFinish:(FileDownloadURLConnection*)theConnection
{	
	NSString* urlKey = [theConnection.url description];
	NSString* callbackId = [theConnection.context objectForKey:@"callbackId"];
	NSString* appId = [theConnection.context objectForKey:@"appId"];
	NSString* targetFolder = [self appFilePath:appId];
	
	BinaryDownloader* bdPlugin = [[self appDelegate] getCommandInstance:BINARY_DOWNLOAD_PLUGIN];
	if (bdPlugin != nil) {
		[bdPlugin next:urlKey delegate:self];
	} else {
		NSString* errorString = [NSString stringWithFormat:@"Plugin '%@' not found.", BINARY_DOWNLOAD_PLUGIN];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}		
	
	ZipUtil* zuPlugin = [[self appDelegate] getCommandInstance:ZIP_UTIL_PLUGIN];
	if (zuPlugin != nil)
	{
		ZipOperation* zipOp = [[ZipOperation alloc] initAsDeflate:NO withSource:theConnection.filePath target:targetFolder andContext:theConnection.context];
		zipOp.delegate = self;
		[zuPlugin unzip:zipOp];
		[zipOp release];
	}
	else 
	{
		NSString* errorString = [NSString stringWithFormat:@"Plugin '%@' not found.", ZIP_UTIL_PLUGIN];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}
}

- (void) connectionDownloadProgress:(FileDownloadURLConnection*)theConnection 
						 totalBytes:(u_int64_t)totalBytes 
						   newBytes:(u_int64_t)newBytes
{
	// COMMENTED OUT - since 'fetch' doesn't care about any of this
	
//	NSString* callbackId = [theConnection.context objectForKey:@"callbackId"];
//	
//	NSString* url = [theConnection.url description];
//	NSDictionary* progressDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:url, theConnection.filePath, theConnection.contentLength, totalBytes, nil] 
//															 forKeys:[NSArray arrayWithObjects:@"url", @"filePath", @"contentLength", @"bytesDownloaded", nil]];
//	NSDictionary* jsDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:progressDict, nil] 
//													   forKeys:[NSArray arrayWithObjects:@"downloadProgress", nil]];
//	
//	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsDictionary:jsDict];
//	[super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
	NSLog(@"Download Progress: %llu of %@ (%.1f%%)", totalBytes, theConnection.contentLength, ((totalBytes*100.0)/[theConnection.contentLength integerValue]));
}

#pragma mark -
#pragma mark ZipOperationDelegate

- (void) zipResult:(ZipResult*)result
{
	NSString* callbackId = [result.context objectForKey:@"callbackId"];
	NSString* appId = [result.context objectForKey:@"appId"];
	NSString* appUrl = [self appUrl:appId];
	
	PluginResult* pluginResult = nil;
	if (result.ok) {
		pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:appUrl];
		[super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
	} else {
		NSString* errorString = [NSString stringWithFormat:@"Error when un-zipping downloaded file: %@", result.source];
		pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}
}

- (void) zipProgress:(ZipProgress*)progress
{
	// COMMENTED OUT - since 'fetch' doesn't care about any of this
	
//	NSString* callbackId = [progress.context objectForKey:@"callbackId"];
//	
//	NSDictionary* jsDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[progress toDictionary], nil] 
//													   forKeys:[NSArray arrayWithObjects:@"zipProgress", nil]];
//	
//	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsDictionary:jsDict];
//	[super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
	
	NSLog(@"%@ Progress: %llu of %llu", (progress.zip? @"Zip":@"Unzip"), progress.entryNumber, progress.entryTotal);
}

#pragma mark -
#pragma mark PrivateMethods

- (NSString*) __makeLibrarySubfolder:(NSString*)foldername
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* subfolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:foldername];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* error = nil;
	
	if (![fileManager fileExistsAtPath:subfolderPath])
	{
		[fileManager createDirectoryAtPath:subfolderPath withIntermediateDirectories:NO 
								attributes:nil error:&error]; 
	}
	
	if (error != nil) {
		NSLog(@"%s:%s:%d error - %@", __FILE__, __PRETTY_FUNCTION__, __LINE__, error);
		return nil;
	}
	
	return subfolderPath;
}

- (BOOL) __clearLibrarySubfolder:(NSString*)foldername
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* subfolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:foldername];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	NSError* error = nil;
	BOOL retVal = NO;
	
	if ([fileManager removeItemAtPath:subfolderPath error:&error]) 
	{
		retVal = [fileManager createDirectoryAtPath:subfolderPath withIntermediateDirectories:NO 
										 attributes:nil error:&error];
	} 
	
	if (error != nil) {
		NSLog(@"%s:%s:%d error - %@", __FILE__, __PRETTY_FUNCTION__, __LINE__, error);
	}
	
	return retVal;
}	

@end
