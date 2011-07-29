//
//  ZipPlugin.m
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//


#import <Foundation/Foundation.h>
#import "ZipArchive.h"
#import "ZipOperation.h"

#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/PGPlugin.h>
#else
    #import "PGPlugin.h"
#endif

@interface ZipUtil : PGPlugin < ZipOperationDelegate > {

}

@property (nonatomic, retain) NSOperationQueue* operationQueue;

- (void) unzip:(ZipOperation*)zipOperation;
- (void) zip:(ZipOperation*)zipOperation;

- (void) unzip:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) zip:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
