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

#define verifyNotReceived(receiver) verifyCount(receiver, times(0))


@interface TestCPSocketConnection : SenTestCase {
    CPSocketConnection<GCDAsyncSocketDelegate> *_conn;
    CPPort *_port;
    GCDAsyncSocket *_socket;
    id<CPSocketConnectionDelegate> _connDelegate;
}
@end

@implementation TestCPSocketConnection

- (void)setUp
{
    _port = mock([CPPort class]);
    _socket = mock([GCDAsyncSocket class]);
    [given([_socket isConnected]) willReturnBool:YES];
    
    _conn = (id)[[CPSocketConnection alloc] initWithSocket:_socket];
    [_conn setPort:_port];
    
    _connDelegate = mockProtocol(@protocol(CPSocketConnectionDelegate));
    [_conn setDelegate:_connDelegate];
}

- (void)disconnectSocketWithCode:(int)code
{
    [given([_socket isConnected]) willReturnBool:NO];
    
    [_conn socketDidDisconnect:_socket withError:[NSError errorWithDomain:GCDAsyncSocketErrorDomain code:code userInfo:nil]];
}


#pragma mark - When disconnect is requested:

- (void)testWhenDisconnectRequestedShouldDisconnectSocket
{
    [_conn disconnect];
    [verify(_socket) disconnect];
}

- (void)testWhenDisconnectRequestedShouldNilSocketDelegate
{
    [_conn disconnect];
    [verify(_socket) synchronouslySetDelegate:nil];
}

- (void)testWhenDisconnectRequestedShouldNotNotifyPortOfDisconnect
{
    [_conn disconnect];
    [verifyNotReceived(_port) connectionDidClose:_conn];
}

- (void)testWhenDisconnectRequestedShouldNotifyDelegateOfDisconnect
{
    [_conn disconnect];
    [verify(_connDelegate) connectionDidDisconnect:_conn];
}


#pragma mark - When connection closed by remote:

- (void)testWhenSocketClosesShouldDisconnectSocket
{
    [self disconnectSocketWithCode:GCDAsyncSocketClosedError];
    [verify(_socket) disconnect];
}

- (void)testWhenSocketClosesShouldNilSocketDelegate
{
    [self disconnectSocketWithCode:GCDAsyncSocketClosedError];
    [verify(_socket) synchronouslySetDelegate:nil];
}

- (void)testWhenSocketClosesShouldNotifyPortOfDisconnect
{
    [self disconnectSocketWithCode:GCDAsyncSocketClosedError];
    [verify(_port) connectionDidClose:_conn];
}

- (void)testWhenSocketClosesShouldNotifyDelegateOfDisconnect
{
    [self disconnectSocketWithCode:GCDAsyncSocketClosedError];
    [verify(_connDelegate) connectionDidDisconnect:_conn];
}


#pragma mark - When a socket error occurs:

- (void)testWhenSocketErrorOccursShouldNotifyPortOfDisconnect
{
    [self disconnectSocketWithCode:GCDAsyncSocketOtherError];
    [verify(_port) connectionDidClose:_conn];
}

- (void)testWhenSocketErrorOccursShouldNotifyDelegateOfDisconnect
{
    [self disconnectSocketWithCode:GCDAsyncSocketOtherError];
    [verify(_connDelegate) connectionDidDisconnect:_conn];
}

- (void)testWhenSocketErrorOccursShouldNilSocketDelegate
{
    [self disconnectSocketWithCode:GCDAsyncSocketOtherError];
    [verify(_socket) synchronouslySetDelegate:(id)anything()];
    [verify(_socket) setDelegate:anything()];
}

- (void)testWhenSocketErrorOccursShouldNotifyDelegateOfError
{
    [self disconnectSocketWithCode:GCDAsyncSocketOtherError];
    [verify(_connDelegate) connection:_conn didRaiseError:(id)instanceOf([NSError class])];
}

@end
