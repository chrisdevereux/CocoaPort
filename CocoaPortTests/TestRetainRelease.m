//
//  TestRetainRelease.m
//  CocoaPort
//
//  Created by Chris Devereux on 09/10/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import "TestRetainRelease.h"
#import "CPPort.h"
#import "CPObservationHandle.h"
#import "CPInAppConnection.h"
#import <OCMock/OCMock.h>

@interface ObjectHolder : NSObject
@property (strong, nonatomic) id property;
@end

@implementation ObjectHolder
@end

@implementation TestRetainRelease {
    CPPort* port1;
    CPPort* port2;
}

- (void) setUp
{
    id<CPConnection> connection1;
    id<CPConnection> connection2;
    [CPInAppConnection conection:&connection1 toConnection:&connection2];
    
    port1 = [[CPPort alloc] init];
    port2 = [[CPPort alloc] init];
    [port1 connect:connection1];
    [port2 connect:connection2];
}

- (void) requireDeallocation:(id(^)(void))aBlock
{
    __weak id deallocMe;
    
    @autoreleasepool {
        deallocMe = aBlock();
    }
    
    @autoreleasepool {
        [port1 flushReleases];
        [port2 flushReleases];
    }
    
    STAssertNil(deallocMe, @"Object leaked: %@", deallocMe);
}

- (void) testSentProxy
{
    [self requireDeallocation:^id{
        id testObj = [[NSObject alloc] init];
        
        port1.rootObject = [[ObjectHolder alloc] init];
        [[port2 sendTo:port2.remote] setProperty:[port2 reference:testObj]];
        
        STAssertNotNil([port1.rootObject property], nil);
        
        [port1.rootObject setProperty:nil];
        return testObj;
    }];
}

- (void) testReturnByReference
{
    [self requireDeallocation:^id{
        id testObj = [[NSObject alloc] init];
        
        port1.rootObject = [[ObjectHolder alloc] init];
        [port1.rootObject setProperty:testObj];
        
        [port2 send:[port2.remote property] refResponse:^(id response, NSError *error) {
            // released...
        }];
        
        [port1.rootObject setProperty:nil];
        return testObj;
    }];
}

- (void) testInArgument
{
    [self requireDeallocation:^id{
        id testObj = [[NSObject alloc] init];
        
        port1.rootObject = [[ObjectHolder alloc] init];
        [port1.rootObject setProperty:testObj];
        
        [port2 send:[port2.remote property] refResponse:^(id response, NSError *error) {
            [response setValue:response forKey:response];
            // released...
        }];
        
        [port1.rootObject setProperty:nil];
        return testObj;
    }];
}

- (void) testCopy
{
    [self requireDeallocation:^id{
        id testObj = [[NSMutableArray alloc] initWithObjects:@"a", @"b", nil];
        
        port1.rootObject = [[ObjectHolder alloc] init];
        [port1.rootObject setProperty:testObj];
        
        [port2 send:[[port2.remote property] copy] refResponse:^(id response, NSError *error) {
            [response setValue:response forKey:response];
            // released...
        }];
        
        [port1.rootObject setProperty:nil];
        return testObj;
    }];
}

- (void) testKVO
{
    [self requireDeallocation:^id{
        port1.rootObject = [NSMutableDictionary dictionary];
        __block id update;
        
        CPObservationHandle* handle = [port2 addObserverOfRemoteObject:port2.remote keypath:@"foo" copyResponses:^(id response, NSError *error) {
            update = response;
        }];
        
        [port1.rootObject setValue:@"bar" forKey:@"foo"];
        STAssertEqualObjects(update, @"bar", @"Update not send");
        [port1.rootObject setValue:@"bar1" forKey:@"foo"];
        STAssertEqualObjects(update, @"bar1", @"Update not send");
        
        [handle stop];
        
        port1.rootObject = nil;
        return port1.rootObject;
    }];
}

@end
