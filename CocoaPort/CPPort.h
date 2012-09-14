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

@protocol CPPortDelegate;
@protocol CPPortMessage;
@protocol CPConnection;

@class CPObservationHandle;

typedef void(^CPResponseHandler)(id response, NSError* error);


@interface CPPort : NSObject

@property (strong, nonatomic) id rootObject;
@property (unsafe_unretained, nonatomic) id<CPPortDelegate> delegate;
@property (assign, readonly, nonatomic) dispatch_queue_t queue;

- (id) initWithQueue:(dispatch_queue_t)delegateQueue;

- (void) connect:(id<CPConnection>)connection;

/**
 Stops the connection, sends an error to any pending responses, and
 releases all references to local objects.
*/
- (void) disconnect;


#pragma mark - Futures:

/**
 Sends the remote invocation _message_ and returns a *remote reference* to the result
*/
- (void) send:(id)message refResponse:(CPResponseHandler)handler;

/**
 Sends the remote invocation _message_ and returns an *archived copy* of the result.
 
 @important
 The result of _message_, when evaluated remotely, must conform to NSCoding.
*/
- (void) send:(id)message copyResponse:(CPResponseHandler)handler;

/**
 Returns a proxy for sending a non-returning message to the remote reference _remote_
*/
- (id) sendTo:(id)remote;

/**
 Returns a reference to the remote rootObject.
*/
- (id) remote;

/**
 Returns a proxy refering to _localObject_, suitable for passing references to local
 objects as arguments to remote invocations.
 
 @important
 Care must be taken if the proxy is stored, as it can only be treated as reference to
 _localObject_ if it is sent over the port.
*/
- (id) reference:(id)localObject;

#pragma mark - KVO:


- (CPObservationHandle*) addObserverOfRemoteObject:(id)remoteObj keypath:(NSString*)keypath refResponses:(CPResponseHandler)handler;

- (CPObservationHandle*) addObserverOfRemoteObject:(id)remoteObj keypath:(NSString*)keypath copyResponses:(CPResponseHandler)handler;

#pragma mark - Interface to CPConnection:

/**
 Called by the connection when it receives a message.
*/
- (void) connection:(id<CPConnection>)connection didReceiveMessageWithData:(NSData*)payloadData;

/**
 Called by the connection when it closes, expectedly or otherwise.
 
 Note that this will not result in [CPConnection disconnect] being
 sent to the connection, so the connection should perform any cleanup needed
 in addition to sending this.
*/
- (void) connectionDidClose:(id<CPConnection>)connection;


#pragma mark - Dispatching messages:

- (void) sendPortMessage:(id<CPPortMessage>)portMessage;


#pragma mark - Managing references and uniqing:

- (NSData*) retainingHandleForObject:(id)object;
- (void) releaseObjectWithHandle:(NSData*)objectID;

- (id) objectForHandle:(NSData*)objectID;


#pragma mark - Managing pending responses:

- (NSData*) registerResponseHandler:(CPResponseHandler)handler;
- (void) removeResponseHandlerForID:(NSData*)handler;

- (CPResponseHandler) lookupResponseHandler:(NSData*)handlerID;


#pragma mark - KVO Support:

- (void) removeObserverOfRemoteObjectWithUID:(NSData*)uid;


#pragma mark - Error handling:

- (void) raiseError:(NSError*)err local:(BOOL)locally;

@end


@protocol CPPortDelegate <NSObject>
@optional

- (void) port:(CPPort*)port didRaiseRemoteError:(NSError*)error;
- (void) port:(CPPort*)port didRaiseLocalError:(NSError*)error;

- (void) portDidDisconnect:(CPPort*)port;

@end


enum {
	kCPInvokeMsgExceptionRaised,
	kCPInvokeMsgNoKnownMethod,
	kCPInvokeMsgSignatureMismatch,
	kCPInvokeMsgInvalidArgumentType,
	kCPInvokeMsgInvalidReturnType,
	
	kCPPortBadReference,
	kCPPortConnectionClosed
};
OBJC_EXTERN NSString* const CPPortErrorDomain;
