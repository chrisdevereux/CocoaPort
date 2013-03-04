//
//  TestCPPort.m
//  CocoaPort
//
//  Created by Chris Devereux on 27/02/2013.
//  Copyright (c) 2013 Chris Devereux. All rights reserved.
//

#import "CPPort.h"
#import "CPSocketConnection.h"
#import "CPObservationManager.h"

@interface TestCPPortConnectedState : SenTestCase {
    CPPort* _port;
    CPObservationManager *_observationManager;
    id<CPPortDelegate> _delegate;
    id<CPConnection> _connection;
}

@end

@implementation TestCPPortConnectedState

- (void)setUp
{
    _port = [[CPPort alloc] init];
    
    _observationManager = mock([CPObservationManager class]);
    [_port setValue:_observationManager forKey:@"observationManager"];
    
    _delegate = mockProtocol(@protocol(CPPortDelegate));
    _port.delegate = _delegate;
    
    _connection = mock([CPSocketConnection class]);
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

- (void)testOnDisconnectPortFlushesAllObservers
{
    [_port disconnect];
    [verify(_observationManager) removeAllObservers];
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
