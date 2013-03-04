//
//  TestCPObservationManager.m
//  CocoaPort
//
//  Created by Chris Devereux on 03/03/2013.
//  Copyright (c) 2013 Chris Devereux. All rights reserved.
//

#import "CPObservationManager.h"

@interface TestCPObservationManager : SenTestCase {
    CPObservationManager *manager;
}
@end

@implementation TestCPObservationManager

- (void)setUp
{
    manager = [[CPObservationManager alloc] init];
}

- (void)tearDown
{
    manager = nil;
}

- (void)setUpDummyObservationWithKeypath:(NSString *)keypath object:(NSObject **)objectPtr uid:(NSData **)uidPtr
{
    static NSUInteger uidVal = 1;
    NSData *uid = [NSData dataWithBytes:&uidVal length:sizeof(uidVal)];
    uidVal++;
    
    id object = [[NSMutableDictionary alloc] init];
    [object setValue:@"bar" forKey:keypath];
    
    [manager addObserverForObject:object keyPath:@"foo" uid:uid usingBlock:^(id change) {}];
    [object setValue:@"baz" forKey:keypath];
    
    *objectPtr = object;
    *uidPtr = uid;
}

- (void)testShouldReleaseObservedObjectAndUIDWhenObservationEnds
{
    __weak id weakObject;
    __weak id weakUID;
    
    @autoreleasepool {
        [self setUpDummyObservationWithKeypath:@"foo" object:&weakObject uid:&weakUID];
        [manager removeObserverWithUID:weakUID];
    }

    assertThat(weakObject, nilValue());
    assertThat(weakUID, nilValue());
}

- (void)testShouldReleaseObservedObjectAndUIDWhenObservationsAreFlushed
{
    __weak id weakObject;
    __weak id weakUID;
    
    @autoreleasepool {
        [self setUpDummyObservationWithKeypath:@"foo" object:&weakObject uid:&weakUID];
        [manager removeAllObservers];
    }
    
    assertThat(weakObject, nilValue());
    assertThat(weakUID, nilValue());
}

@end
