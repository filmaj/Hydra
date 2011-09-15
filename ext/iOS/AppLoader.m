//
//  AppLoader.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "AppLoader.h"
#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/PhoneGapDelegate.h>
    #import <PhoneGap/PGDebug.h>
#else
    #import "PhoneGapDelegate.h"
    #import "PGDebug.h"
#endif
#import "BinaryDownloader.h"
#import	"FileDownloadURLConnection.h"
#import "ZipUtil.h"
#import "UIWebView+PGAdditions.h"

#define HYDRA_DOWNLOADS_FOLDER	@"HydraDownloads"
#define HYDRA_APPS_FOLDER		@"HydraApps"
#define BINARY_DOWNLOAD_PLUGIN	@"com.nitobi.BinaryDownloader"
#define ZIP_UTIL_PLUGIN			@"com.nitobi.ZipUtil"
#define THIS_PLUGIN             @"com.nitobi.AppLoader"

@interface NSObject (AppLoader_PrivateMethods)

- (NSString*) __makeLibrarySubfolder:(NSString*)foldername;
- (BOOL) __clearLibrarySubfolder:(NSString*)foldername;
- (NSError*) __removeFolder:(NSString*)appId;

- (void) removeStatusBarOverlay;
- (void) showStatusBarOverlay;

- (BOOL) removeNavigationBar;
- (BOOL) addNavigationBar;

- (void) onStatusBarFrameChange:(NSNotification*)notification;

@end


@implementation AppLoader

@synthesize downloadsFolder, appsFolder, navigationBar, overlayView;


- (PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (AppLoader*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
        [self __clearLibrarySubfolder:HYDRA_DOWNLOADS_FOLDER];
		self.downloadsFolder = [self __makeLibrarySubfolder:HYDRA_DOWNLOADS_FOLDER];
		self.appsFolder = [self __makeLibrarySubfolder:HYDRA_APPS_FOLDER];
        
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusBarFrameChange:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
	return self;
}

- (NSString*) appFilePath:(NSString*)appId
{
	return [NSString stringWithFormat:@"%@/%@", self.appsFolder, appId];
}

- (NSString*) unzipTempFilePath:(NSString*)appId
{
	return [NSString stringWithFormat:@"%@/%@", self.downloadsFolder, [NSString stringWithFormat:@"%@-temp", appId]];
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
    [self removeStatusBarOverlay];
	
	NSURLRequest* homeRequest = [NSURLRequest requestWithURL:[self homeUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
	[self.webView loadRequest:homeRequest];
}

- (NSError*) __removeApp:(NSString*)appId
{
	NSString* appFilePath = [self appFilePath:appId];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* error = nil;
	
	if ([fileManager fileExistsAtPath:appFilePath]) 
	{
		[fileManager removeItemAtPath:appFilePath error:&error];
	} 
	else 
	{
		NSString* description = [NSString stringWithFormat:NSLocalizedString(@"Hydra app not found: %@", @"Hydra app not found: %@"), appFilePath];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              description, NSLocalizedFailureReasonErrorKey,
                              nil];
        error = [NSError errorWithDomain:THIS_PLUGIN code:AppLoaderErrorAppNotFound userInfo:userInfo];
	}
    
    return error;
}

- (void) onStatusBarFrameChange:(NSNotification*)notification
{
    NSValue* value = [[notification userInfo] objectForKey:UIApplicationStatusBarFrameUserInfoKey];
    if (value) {
        CGRect oldFrame = [value CGRectValue];
        CGRect newFrame = [[UIApplication sharedApplication] statusBarFrame];
        
        BOOL isIncreasedHeightStatusBar = (newFrame.size.height > oldFrame.size.height);
        if (isIncreasedHeightStatusBar) {
            NSLog(@"Removing status bar overlay.");
            [self removeStatusBarOverlay];
        } else {
            NSLog(@"Adding status bar overlay.");
            [self showStatusBarOverlay];
        }
    }
}

#pragma mark -
#pragma mark StatusBarOverlay

- (void) showStatusBarOverlay
{
    if (self.overlayView) {
        return;
    }
    
    UIWindow* statusWindow = [[UIWindow alloc] initWithFrame:[[UIApplication sharedApplication] statusBarFrame]];
    statusWindow.windowLevel = UIWindowLevelStatusBar+1.0f;
    statusWindow.hidden = NO;
    statusWindow.backgroundColor = [UIColor clearColor];
    [statusWindow makeKeyAndVisible];
    
    self.overlayView = [[[StatusBarOverlayView alloc] init] autorelease];  
    self.overlayView.frame = [[UIApplication sharedApplication] statusBarFrame];  
    self.overlayView.backgroundColor = [UIColor clearColor];  
    self.overlayView.delegate = self;
    [statusWindow addSubview:self.overlayView]; 
    
    // make the main window key, if not the keyboard won't show
    [[self appDelegate].window makeKeyAndVisible];    
}

- (void) removeStatusBarOverlay
{
    if (!self.overlayView) {
        return;
    }
    
    [self removeNavigationBar];
    
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
}

#pragma mark -
#pragma mark NavigationBar

- (BOOL) removeNavigationBar
{
	if (!self.navigationBar) {
		return NO;
	}
	
    [self.webView pg_removeSiblingView:self.navigationBar withAnimation:YES];
    [self.webView pg_relayout:NO];
    
	self.navigationBar = nil;
	
	return YES;
}

- (BOOL) addNavigationBar
{
	if (self.navigationBar) {
		return NO;
	}
	
    CGFloat height   = 45.0f;
    UIBarStyle style = UIBarStyleDefault;
	
    CGRect toolBarBounds = self.webView.bounds;
	toolBarBounds.size.height = height;
	
    self.navigationBar = [[[UINavigationBar alloc] init] autorelease];
    [self.navigationBar sizeToFit];
    [self.navigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease] animated:NO];
    self.navigationBar.autoresizesSubviews    = YES;
    self.navigationBar.userInteractionEnabled = YES;
    self.navigationBar.barStyle               = style;
	
	[self.webView pg_addSiblingView:self.navigationBar withPosition:PGLayoutPositionTop withAnimation:YES];
    
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back") style:UIBarButtonItemStyleBordered 
                                                            target:self action:@selector(goBack)];
    self.navigationBar.topItem.leftBarButtonItem = item;
    
    [item release];
	
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
        [self showStatusBarOverlay];
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
        // remove any previous existing download
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:downloadFilePath error:&error]; 
        
		NSDictionary* context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:appId, uri, callbackId, downloadFilePath, nil] 
															forKeys:[NSArray arrayWithObjects:@"appId", @"uri", @"callbackId", @"filePath", nil]];
		DownloadQueueItem* queueItem = [[DownloadQueueItem newItem:uri withFilepath:downloadFilePath context:context andCredential:credential] autorelease];
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
    PluginResult* pluginResult = nil;
	
	// ///////////////////////////////////////////
    
	NSError* error = [self __removeApp:appId];
    if (error == nil)
    {
        pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
        [super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    }
    else
    {
        pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[error localizedDescription]];
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
	NSString* unzipFolder = [self unzipTempFilePath:appId];
	
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
		ZipOperation* zipOp = [[ZipOperation alloc] initAsDeflate:NO withSource:theConnection.filePath target:unzipFolder andContext:theConnection.context];
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
	DLog(@"Download Progress: %llu of %@ (%.1f%%)", totalBytes, theConnection.contentLength, ((totalBytes*100.0)/[theConnection.contentLength integerValue]));
}

#pragma mark -
#pragma mark ZipOperationDelegate

- (void) zipResult:(ZipResult*)result
{
	NSString* callbackId = [result.context objectForKey:@"callbackId"];
	NSString* appId = [result.context objectForKey:@"appId"];
	NSString* appUrl = [self appUrl:appId];
    NSString* appPath = [self appFilePath:appId];
	NSError* error = nil;
    
	PluginResult* pluginResult = nil;
	if (result.ok && !result.zip) { // only interested in unzip
        
        // remove any previous existing app, since the unzip was successful
        [self __removeApp:appId];

        // move result.target to appPath
        [[NSFileManager defaultManager] moveItemAtPath:result.target toPath:appPath error:&error];
        
		if (error == nil) {
            pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:appUrl];
            [super writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
        } else {
            pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:[error localizedDescription]];
            [super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
        }
        
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
	
	DLog(@"%@ Progress: %llu of %llu", (progress.zip? @"Zip":@"Unzip"), progress.entryNumber, progress.entryTotal);
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
    
    if (![fileManager fileExistsAtPath:subfolderPath]) {
        return NO;
    }
	
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

#pragma mark -
#pragma StatusBarOverlayDelegate

- (void) statusBarTapped:(NSUInteger)numberOfTaps
{
    if (numberOfTaps != 2) {
        return;
    }
    
    if (self.navigationBar) {
        [self removeNavigationBar];
    } else {
        [self addNavigationBar];
    }
}

@end

@implementation StatusBarOverlayView

@synthesize delegate;

- (void) dealloc
{
    self.delegate = nil;
    [super dealloc];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event 
{
    for (UITouch *touch in touches) 
    {
        if (self.delegate) {
            [self.delegate statusBarTapped:touch.tapCount];
        }
    }
}


@end
