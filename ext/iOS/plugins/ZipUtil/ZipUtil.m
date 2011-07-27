//
//  ZipPlugin.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "ZipUtil.h"


@implementation ZipUtil

@synthesize operationQueue;

-(PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (ZipUtil*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
	return self;
}

#pragma mark -
#pragma mark ZipOperationDelegate

- (void) zipResult:(ZipResult*)result
{
	NSDictionary* jsDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[result toDictionary], nil] 
													   forKeys:[NSArray arrayWithObjects:@"zipResult", nil]];

	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsDictionary:jsDict];
	if (result.ok) {
		[super writeJavascript:[pluginResult toSuccessCallbackString:result.context]];
	} else {
		[super writeJavascript:[pluginResult toErrorCallbackString:result.context]];
	}
}

- (void) zipProgress:(ZipProgress*)progress
{
	NSDictionary* jsDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[progress toDictionary], nil] 
													   forKeys:[NSArray arrayWithObjects:@"zipProgress", nil]];
	
	PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsDictionary:jsDict];
	[super writeJavascript:[pluginResult toSuccessCallbackString:progress.context]];
}


#pragma mark -
#pragma mark PhoneGap commands

- (void) unzip:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 3) {
		return;
	}
	
	NSString* callbackId = [arguments objectAtIndex:0];
	NSString* sourcePath = [arguments objectAtIndex:1];
	NSString* targetFolder = [arguments objectAtIndex:2];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) 
	{
		ZipOperation* zipOp = [[ZipOperation alloc] initAsDeflate:NO withSource:sourcePath target:targetFolder andContext:callbackId];
		zipOp.delegate = self;
		[self.operationQueue addOperation:zipOp];
		[zipOp release];
	}
	else 
	{
		NSString* errorString = [NSString stringWithFormat:@"Source path '%@' does not exist.", sourcePath];
		PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:errorString];
		[super writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
	}
}

- (void) zip:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    // FUTURE: TODO:
}

@end
