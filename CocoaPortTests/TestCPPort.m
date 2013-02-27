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
    id<CPPortDelegate> _delegate;
    id<CPConnection> _connection;
}

@end

@implementation TestCPPortConnectedState

- (void)setUp
{
    _port = [[CPPort alloc] init];
    _connection = mock([CPSocketConnection class]);
    _delegate = mockProtocol(@protocol(CPPortDelegate));
    
    _port.delegate = _delegate;
    [_port connect:_connection];
}

- (void)tearDown
{
    _port = nil;
    _connection = nil;
}

- (void)testOnDisconnectPortPropagatesDisconnection
{
    [_port disconnect];
    [verify(_connection) disconnect];
}

- (void)testOnDisconnectPortErrorsOutstandingRequests
{
    __block NSError *errorReceived;
    
    [_port send:[_port.remote allObjects] copyResponse:^(id response, NSError *error) {
        errorReceived = error;
    }];
    
    [_port disconnect];
    assertThat(errorReceived, notNilValue());
}

@end
