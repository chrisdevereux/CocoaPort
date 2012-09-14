//
//  CPNilPlaceholder.m
//  CocoaPort
//
//  Created by Chris Devereux on 14/09/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import "CPNilPlaceholder.h"

@implementation CPNilPlaceholder

+ (instancetype) nilPlaceholder
{
    static CPNilPlaceholder* shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	return [super init];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError *__autoreleasing *)err
{
    *resultPtr = nil;
    return YES;
}

@end
