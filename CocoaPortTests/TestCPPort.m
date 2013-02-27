//
//  TestCPPort.m
//  CocoaPort
//
//  Created by Chris Devereux on 27/02/2013.
//  Copyright (c) 2013 Chris Devereux. All rights reserved.
//

#import "CPPort.h"
#import "CPSocketConnection.h"

@interface TestCPPortConnectedState : SenTestCase {
    CPPort* _port;
    id<CPConnection> _connection;
}

@end

@implementation TestCPPortConnectedState

- (void)setUp
{
    _port = [[CPPort alloc] init];
    _connection = mock([CPSocketConnection class]);
    
    [_port connect:_connection];
}

- (void)tearDown
{
    _port = nil;
    _connection = nil;
}

- (void)testPortPropagatesDisconnection
{
    [_port disconnect];
    [verify(_connection) disconnect];
}

@end
