// Copyright (c) 2012 Chris Devereux

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CPSocketServer.h"
#import "CPSocketConnection.h"

@implementation CPSocketServer {
	GCDAsyncSocket* _listenerSocket;
	dispatch_queue_t _incomingQueue;
}

- (void) dealloc
{
	[_listenerSocket synchronouslySetDelegate:nil delegateQueue:NULL];
	[self stop];
}


- (BOOL) listenForConnectionsOnPort:(uint16_t)inPort error:(NSError *__autoreleasing *)error
{
	[self stop];
	_active = YES;
	
	_incomingQueue = dispatch_get_current_queue();
	dispatch_retain(_incomingQueue);
	
	_listenerSocket = [[GCDAsyncSocket alloc] init];
	[_listenerSocket setDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	
	if (![_listenerSocket acceptOnPort:inPort error:error]) {
		[self stop];
		return NO;
	}
	
	return YES;
}


- (uint16_t) portNumber
{
	return [_listenerSocket localPort];
}


- (void) stop
{
	_active = NO;
	
	[_listenerSocket setDelegate:nil delegateQueue:NULL];
	[_listenerSocket disconnect];
	_listenerSocket = nil;
	
	if (_incomingQueue) {
		dispatch_release(_incomingQueue);
		_incomingQueue = NULL;
	}
}


#pragma mark - As a GCDAsyncSocket:

- (void) socket:(GCDAsyncSocket*)asyncSocket didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	if (!_active)
		return;
	
	[newSocket setDelegateQueue:_incomingQueue];
	CPSocketConnection* connection = [[CPSocketConnection alloc] initWithSocket:newSocket];
									  
	dispatch_async(_incomingQueue, ^{
		@autoreleasepool {
			[_delegate server:self didEstablishConnection:connection];
		}
	});
}

@end
