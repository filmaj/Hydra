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
    // TODO:
    //TODO: call the success callback (using the context), send progress data
}

- (void) zipProgress:(ZipProgress*)progress
{
    // TODO:
    //TODO: call the success callback (using the context), send progress data
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
//		NSString* jsCallBack = [[NSString alloc] initWithFormat:@"%@._onZipFail(%@, \"%@\",\"%@\", \"%@\", \"%@\");", 
//								@"TODO:", @"false", sourcePath, targetFolder, @"Failed to unzip", context];
//		
//		[super writeJavascript:jsCallBack];
//		[jsCallBack release];
        
        //TODO: call the fail callback
	}
}

- (void) zip:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    // FUTURE:
}

@end
