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

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class CPSocketConnection;
@protocol CPSocketServerDelegate;


@interface CPSocketServer : NSObject <GCDAsyncSocketDelegate>

@property (unsafe_unretained, nonatomic) id<CPSocketServerDelegate> delegate;
@property (assign, readonly, nonatomic) uint16_t portNumber;

@property (assign, readonly, nonatomic) BOOL active;

/**
 Listens for connections on _inPort_. For each connection, creates a CPSocketConnection
 and calls [SPSocketServerDelegate server:didEstablishConnection:].
 
 Delegate callbacks will be sent to the dispatch queue that this method is called from.
*/
- (BOOL) listenForConnectionsOnPort:(uint16_t)inPort error:(NSError *__autoreleasing *)error;

/**
 Stop listening for connections.
*/
- (void) stop;

@end



@protocol CPSocketServerDelegate <NSObject>

- (void) server:(CPSocketServer*)server didEstablishConnection:(CPSocketConnection*)connection;

@end