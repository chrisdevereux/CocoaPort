//
//  TestCPSocketConnection.m
//  CocoaPort
//
//  Created by Chris Devereux on 27/02/2013.
//  Copyright (c) 2013 Chris Devereux. All rights reserved.
//

#import "CPSocketConnection.h"
#import "CPPort.h"
#import "GCDAsyncSocket.h"

@interface TestCPSocketConnection : SenTestCase {
    CPSocketConnection *_conn;
    CPPort *_port;
    GCDAsyncSocket *_socket;
}
@end

@implementation TestCPSocketConnection

- (void)setUp
{
    _port = mock([CPPort class]);
    _socket = mock([GCDAsyncSocket class]);
    [given([_socket isConnected]) willReturnBool:YES];
    
    _conn = [[CPSocketConnection alloc] initWithSocket:_socket];
    [_conn setPort:_port];
}

- (void)testShouldDisconnectSocketOnDisconnect
{
    [_conn disconnect];
    [verify(_socket) disconnect];
}

- (void)testShouldNilSocketDelegateOnDisconnect
{
    [_conn disconnect];
    [verify(_socket) synchronouslySetDelegate:nil];
}

@end
