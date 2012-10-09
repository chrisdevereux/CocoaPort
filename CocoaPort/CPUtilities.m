//
//  CPUtilities.m
//  CocoaPort
//
//  Created by Chris Devereux on 09/10/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import "CPUtilities.h"

BOOL CPIsRetainingSelectorName(NSString* selName)
{
    static NSRegularExpression* regexp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* err;
        regexp = [[NSRegularExpression alloc] initWithPattern:@"^(alloc|copy|mutableCopy|new)" options:0 error:&err];
        NSCAssert(regexp, @"rexeg error: %@", err);
    });
    
    return [regexp firstMatchInString:selName options:0 range:NSMakeRange(0, [selName length])] != nil;
}

id CPAutorelease(id object)
{
    return [object autorelease];
}
