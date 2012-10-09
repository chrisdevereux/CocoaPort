//
//  TestRetainRelease.m
//  CocoaPort
//
//  Created by Chris Devereux on 09/10/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import "TestRetainRelease.h"
#import "CPPort.h"
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

- (void) testSentProxy
{
    __weak id deallocMeWeak;
    
    @autoreleasepool {
        id deallocMeStrong = [[NSObject alloc] init];
        deallocMeWeak = deallocMeStrong;
        
        port1.rootObject = [[ObjectHolder alloc] init];
        [[port2 sendTo:port2.remote] setProperty:[port2 reference:deallocMeStrong]];
        
        STAssertNotNil([port1.rootObject property], nil);
        
        deallocMeStrong = nil;
        [port1.rootObject setProperty:nil];
    }
    
    @autoreleasepool {
        [port1 flushReleases];
        [port2 flushReleases];
    }
    
    STAssertNil(deallocMeWeak, @"Object leaked");
}

- (void) testReturnByReference
{
    __weak id deallocMeWeak;
    
    @autoreleasepool {
        port1.rootObject = [[ObjectHolder alloc] init];
        [port1.rootObject setProperty:[[NSObject alloc] init]];
        deallocMeWeak = [port1.rootObject property];
        
        [port2 send:[port2.remote property] refResponse:^(id response, NSError *error) {
            // released...
        }];
        
        [port1.rootObject setProperty:nil];
    }
    
    @autoreleasepool {
        [port1 flushReleases];
        [port2 flushReleases];
    }
    
    STAssertNil(deallocMeWeak, @"Object leaked");
}

- (void) testInArgument
{
    __weak id deallocMeWeak;
    
    @autoreleasepool {
        port1.rootObject = [[ObjectHolder alloc] init];
        [port1.rootObject setProperty:[[NSObject alloc] init]];
        deallocMeWeak = [port1.rootObject property];
        
        [port2 send:[port2.remote property] refResponse:^(id response, NSError *error) {
            [response setValue:response forKey:response];
            // released...
        }];
        
        [port1.rootObject setProperty:nil];
    }
    
    @autoreleasepool {
        [port1 flushReleases];
        [port2 flushReleases];
    }
    
    STAssertNil(deallocMeWeak, @"Object leaked");
}

@end
