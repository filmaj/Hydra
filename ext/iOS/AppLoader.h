//
//  AppLoader.h
//
//  Created by Shazron Abdullah
//  Copyright 2011 Nitobi Software Inc.
//

#import <Foundation/Foundation.h>

#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/PGPlugin.h>
#else
    #import "PGPlugin.h"
#endif


@interface AppLoader : PGPlugin {
}

@property (nonatomic, copy)	NSString* downloadsFolder;

- (void) load:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) fetch:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) remove:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
