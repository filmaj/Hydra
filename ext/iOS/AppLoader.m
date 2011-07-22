//
//  AppLoader.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import "AppLoader.h"
#import	"FileDownloadURLConnection.h"
#import "ZipArchive.h"
#import "ZipOperation.h"

@interface NSObject (AppLoader_PrivateMethods)

- (NSError*) _createNSError:(NSString*)description path:(NSString*)path;
- (NSString*) __makeLibrarySubfolder:(NSString*)foldername;
- (BOOL) __clearLibrarySubfolder:(NSString*)foldername;

@end


@implementation AppLoader

@synthesize downloadsFolder;

#define DOWNLOADS_FOLDER		@"HydraDownloads"

-(PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (AppLoader*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
		self.downloadsFolder	= [self __makeLibrarySubfolder:DOWNLOADS_FOLDER];
    }
	return self;
}

#pragma mark -
#pragma mark PhoneGap commands

- (void) load:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 2) {
		return;
	}
    
    NSString* callbackId = [arguments objectAtIndex:0];
    NSString* appId = [arguments objectAtIndex:1];
    
    // TODO: get the location of the app with the id on disk
    // construct a file url, append "index.html" to it
    // send to the successCallback through PluginResult
    // on error, send to failCallback through PluginResult
}

- (void) fetch:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 5) {
		return;
	}
    
    NSString* callbackId = [arguments objectAtIndex:0];
    NSString* appId = [arguments objectAtIndex:1];
    NSString* url = [arguments objectAtIndex:2];
    NSString* username = [arguments objectAtIndex:3];
    NSString* password = [arguments objectAtIndex:4];
    
    // TODO: download the zip file at the url (with the credentials)
    // extract the zip file into the location on disk with the appId
    // from that appId location, construct a file url, append "index.html" to it
    // send to the successCallback through PluginResult
    // on error, send to failCallback through PluginResult
}

- (void) remove:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	if (argc < 2) {
		return;
	}
    
    NSString* callbackId = [arguments objectAtIndex:0];
    NSString* appId = [arguments objectAtIndex:1];
    
    // TODO: get the location of the app with the id on disk
    // delete that folder
    // on success, do nothing
    // on error, send to failCallback through PluginResult
}

@end
