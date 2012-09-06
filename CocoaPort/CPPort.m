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

#import "CPPort.h"
#import "CPConnection.h"
#import "CPReferenceMap.h"
#import "CPEvaluable.h"
#import "CPRemoteInvocation.h"

#import "CPObservationHandle.h"
#import "CPObservationManager.h"

#import "CPFuture.h"
#import "CPSendableProxy.h"

#import <objc/runtime.h>


#define AssertQueue(Q) NSAssert(dispatch_get_current_queue() == Q, @"Method called on wrong queue");

@interface CPVoidSendProxy : NSProxy
- (id) initWithTarget:(id)target port:(CPPort*)port;
@end


#pragma mark -

@implementation CPPort {
	id<CPConnection> _connection;
	id _rootObject;
	
	CPReferenceMap* _referencedObjects;
	CPReferenceMap* _responseHandlers;
	
	CPObservationManager* _observationManager;
	
	dispatch_queue_t _queue;
	
	struct {
		uint8_t didRaiseLocal :1;
		uint8_t didRaiseRemote :1;
		uint8_t didDisconnect :1;
	} _delegateHas;
}

@synthesize delegate = _delegate;


- (id) initWithQueue:(dispatch_queue_t)queue
{
	self = [super init];
	if (!self)
		return nil;
	
	_queue = queue ?: dispatch_get_current_queue();
	dispatch_retain(_queue);
	
	_observationManager = [[CPObservationManager alloc] init];
	
	return self;
}

- (id) init
{
	return [self initWithQueue:nil];
}

- (void) dealloc
{
	[self performBlock:^{
		[self disconnect:YES];
		
		if (_queue) {
			dispatch_release(_queue);
		}
	}];
}

- (void) connect:(id<CPConnection>)connection
{
	if (!connection) {
		[self disconnect:YES];
		return;
	}
	
	[self performBlock:^{
		if (_connection == connection)
			return;
		
		[_connection disconnect];
		
		_responseHandlers = [[CPReferenceMap alloc] init];
		_referencedObjects = [[CPReferenceMap alloc] init];
		
		_connection = connection;
		[_connection setPort:self];
	}];
}

- (void) disconnect
{
	[self disconnect:YES];
}

- (id<CPPortDelegate>) delegate
{
	__block id delegate = nil;
	
	[self performBlock:^{
		delegate = _rootObject;
	}];
	
	return delegate;
}

- (void) setDelegate:(id<CPPortDelegate>)delegate
{
	[self performBlock:^{
		_delegate = delegate;
		
		_delegateHas.didDisconnect = [delegate respondsToSelector:@selector(portDidDisconnect:)];
		_delegateHas.didRaiseLocal = [delegate respondsToSelector:@selector(port:didRaiseLocalError:)];
		_delegateHas.didRaiseRemote = [delegate respondsToSelector:@selector(port:didRaiseRemoteError::)];
	}];
}

- (void) setRootObject:(id)rootObject
{
	[self performBlock:^{
		_rootObject = rootObject;
	}];
}

- (id) rootObject
{
	__block id root = nil;
	
	[self performBlock:^{
		root = _rootObject;
	}];
	
	return root;
}


#pragma mark - Remote messaging:

- (void) send:(id)message copyResponse:(CPResponseHandler)handler
{
	id<CPEvaluable> evaluable = CPConvertFutureExpressionToEvaluable(message);
	CPRemoteInvocation* inv = [[CPRemoteInvocation alloc] initWithMessageSendExpression:evaluable responseHandler:handler copyResponse:YES];
	[self sendPortMessage:inv];
}

- (void) send:(id)message refResponse:(CPResponseHandler)handler
{
	id<CPEvaluable> evaluable = CPConvertFutureExpressionToEvaluable(message);
	CPRemoteInvocation* inv = [[CPRemoteInvocation alloc] initWithMessageSendExpression:evaluable responseHandler:handler copyResponse:NO];
	[self sendPortMessage:inv];
}

- (id) sendTo:(id)remote
{
	return [[CPVoidSendProxy alloc] initWithTarget:remote port:self];
}

- (id) reference:(id)localObject
{
	CPSentProxy* proxy = [[CPSentProxy alloc] init];
	proxy.ref = [self retainingHandleForObject:localObject];
	return proxy;
}

- (id) remote
{
	return [CPRootObjectReferenceFuture futureWithPort:self];
}


#pragma mark - KVO:

- (CPObservationHandle*) addObserverOfRemoteObject:(id)remoteObj keypath:(NSString *)keypath copyResponses:(CPResponseHandler)handler
{
	return [self addObserverOfRemoteObject:remoteObj keypath:keypath sendCopies:YES handler:handler];
}

- (CPObservationHandle*) addObserverOfRemoteObject:(id)remoteObj keypath:(NSString *)keypath refResponses:(CPResponseHandler)handler
{
	return [self addObserverOfRemoteObject:remoteObj keypath:keypath sendCopies:NO handler:handler];
}

- (void) removeObserverOfRemoteObjectWithUID:(NSData*)uid
{
	[self performBlock:^{
		[self removeResponseHandlerForID:uid];
		
		CPPort* remotePort = [self sendTo:[CPRemotePortReferenceFuture futureWithPort:self]];
		[remotePort removeRemoteObserverWithUID:uid];
	}];
}

- (CPObservationHandle*) addObserverOfRemoteObject:(id)remoteObj keypath:(NSString *)keypath sendCopies:(BOOL)sendCopies handler:(CPResponseHandler)handler
{
	__block NSData* uid;
	
	[self performBlock:^{
		uid = [self registerResponseHandler:handler];
		
		CPPort* remotePort = [self sendTo:[CPRemotePortReferenceFuture futureWithPort:self]];
		[remotePort addRemoteObserverWithUID:uid forKeypath:keypath ofLocalObject:remoteObj copyChanges:@(sendCopies)];
	}];
	
	return [[CPObservationHandle alloc] initWithUID:uid port:self];
}


#pragma mark - Interface to CPConnection:

- (void) connection:(id<CPConnection>)connection didReceiveMessageWithData:(NSData *)payloadData
{
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:payloadData];
	[unarchiver setDelegate:(id)self];
	
	id<CPPortMessage> msg = [unarchiver decodeObjectForKey:@"root"];
	NSAssert([msg conformsToProtocol:@protocol(CPPortMessage)], @"Bad port message received");
	[unarchiver finishDecoding];
	
	[self performBlock:^{
		[msg didReceiveOnPort:self];
	}];
}

- (void) connectionDidClose:(id<CPConnection>)connection
{
	[self performBlock:^{
		[self disconnect:NO];
	}];
}


#pragma mark - Dispatching messages:

- (void) sendPortMessage:(id<CPPortMessage>)portMessage
{
	[self performBlock:^{
		[portMessage willSendOnPort:self];
		
		NSMutableData* data = [NSMutableData data];
		NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver setDelegate:(id)self];
		
		[archiver encodeObject:portMessage forKey:@"root"];
		[archiver finishEncoding];
		
		[_connection sendPortMessageWithData:data];
	}];
}


#pragma mark - Managing references:

- (NSData*) retainingHandleForObject:(id)object
{
	__block NSData* resp = nil;
	
	[self performBlock:^{
		resp = [_referencedObjects referenceObject:object];
	}];
	
	return resp;
}

- (void) releaseObjectWithHandle:(NSData*)objectId
{
	[self performBlock:^{
		[_referencedObjects releaseObjectWithUID:objectId];
	}];
}

- (id) objectForHandle:(NSData*)objectID
{
	__block id resp = nil;
	
	[self performBlock:^{
		resp = [_referencedObjects objectForUID:objectID];
	}];
	
	return resp;
}



#pragma mark - Managing pending responses:

- (NSData*) registerResponseHandler:(CPResponseHandler)handler
{
	__block NSData* resp = nil;
	
	[self performBlock:^{
		resp = [_responseHandlers referenceObject:handler];
	}];
	
	return resp;
}

- (CPResponseHandler) lookupResponseHandler:(NSData *)handlerID
{
	__block CPResponseHandler resp = nil;
	
	[self performBlock:^{
		resp = [_responseHandlers objectForUID:handlerID];
	}];
	
	return resp;
}

- (void) removeResponseHandlerForID:(NSData*)handlerID
{
	[self performBlock:^{
		[_responseHandlers releaseObjectWithUID:handlerID];
	}];
}


#pragma mark - Managing observations:

- (void) addRemoteObserverWithUID:(NSData *)uid forKeypath:(NSString *)keypath ofLocalObject:(id)localObject copyChanges:(NSNumber*)inCopy
{
	__unsafe_unretained CPPort* weakSelf = self;
	BOOL copyChanges = [inCopy boolValue];
	
	[_observationManager addObserverForObject:localObject keyPath:keypath uid:uid usingBlock:^(id change) {
		CPPort* remotePort = [weakSelf sendTo:[CPRemotePortReferenceFuture futureWithPort:weakSelf]];
		
		[remotePort receiveUpdate:(copyChanges ? change : [weakSelf reference:change]) forObservationWithUID:uid];
	}];
}

- (void) removeRemoteObserverWithUID:(NSData*)uid
{
	[_observationManager removeObserverWithUID:uid];
}

- (void) receiveUpdate:(id)change forObservationWithUID:(NSData*)uid
{
	[self performBlock:^{
		CPResponseHandler handler = [_responseHandlers objectForUID:uid];
		if (!handler)
			return;
		
		handler(change, nil);
	}];
}


#pragma mark - Handling errors:

- (void) raiseError:(NSError *)err local:(BOOL)locally
{
	AssertQueue(_queue);
	
	if (_delegateHas.didRaiseLocal && locally){
		[_delegate port:self didRaiseLocalError:err];
	}
		
	else if (_delegateHas.didRaiseRemote && !locally) {
		[_delegate port:self didRaiseRemoteError:err];
	}
}


#pragma mark - Private:

- (void) disconnect:(BOOL)notifyConnection
{
	if (!_connection)
		return;
	
	[_connection setPort:nil];
	_connection = nil;
	
	[_responseHandlers enumerateObjectsUsingBlock:^(NSData* uid, CPResponseHandler h){
		h(nil, [NSError errorWithDomain:CPPortErrorDomain code:kCPPortConnectionClosed userInfo:nil]);
	}];
	
	_referencedObjects = nil;
	_responseHandlers = nil;
	
	[_observationManager removeAllObservers];
	
	if (_delegateHas.didDisconnect) {
		[_delegate portDidDisconnect:self];
	}
	
	if (notifyConnection) {
		[_connection disconnect];
	}
}

- (void) performBlock:(dispatch_block_t)block
{
	if (dispatch_get_current_queue() == _queue) {
		block();
	} else {
		dispatch_sync(_queue, block);
	}
}


@end


#pragma mark -

@implementation CPVoidSendProxy {
	id _target;
	CPPort* _port;
}

- (id) initWithTarget:(id)target port:(CPPort*)port
{
	_target = target;
	_port = port;
	
	return self;
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
	return [_target methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	[invocation invokeWithTarget:_target];
	__unsafe_unretained id msg;
	[invocation getReturnValue:&msg];
	id nilReturn = nil;
	[invocation setReturnValue:&nilReturn];
	[_port send:msg refResponse:nil];
}

@end


NSString* const CPPortErrorDomain = @"CPPortErrorDomain";
