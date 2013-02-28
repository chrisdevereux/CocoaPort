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

#import "CPSocketConnection.h"
#import "CPPort.h"
#import "CPSocketMsg.h"
#import "CocoaAsyncSocket/GCD/GCDAsyncSocket.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

enum {
	kCPSocketReadHeader,
	kCPSocketReadPayload
};


@interface CPSocketConnectingDelegate : NSObject <GCDAsyncSocketDelegate>
@property (copy, nonatomic) void(^success)(void);
@property (copy, nonatomic) void(^error)(NSError*);
@end


@implementation CPSocketConnection {
	GCDAsyncSocket* _socket;
	__unsafe_unretained CPPort* _port;
	
	struct {
		uint8_t isRaw :1;
		uint8_t isSecured :1;
	} _currentMessage;
	
	struct {
		uint8_t secureData :1;
		uint8_t receiveSecured :1;
		uint8_t receiveRaw :1;
		uint8_t raiseError :1;
		uint8_t didDisconnect :1;
	} _delegateHas;
	
	struct {
		uint8_t closed :1;
	} _miscFlags;
}


- (id) init
{
	return [self initWithSocket:[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_current_queue()]];
}

- (id) initWithSocket:(GCDAsyncSocket *)socket
{
	NSParameterAssert(socket && [socket isConnected]);
	
	self = [super init];
	if (!self)
		return nil;

	_socket = socket;
	[_socket setDelegate:self];
	[_socket readDataToLength:kCPSocketHeaderSize withTimeout:-1 tag:kCPSocketReadHeader];
	
	return self;
}

- (void) dealloc
{
	[self disconnect];
}


+ (void) connectToAddress:(NSData *)address timeout:(NSTimeInterval)timeout asyncResult:(void (^)(id, NSError *))asyncResult
{
	NSParameterAssert(asyncResult);
	NSParameterAssert(address);
	
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	dispatch_retain(callingQueue);
	
	GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] init];
	CPSocketConnectingDelegate* delegate = [[CPSocketConnectingDelegate alloc] init];
	[socket setDelegate:delegate delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	
	void* delegateKeepAlive = (__bridge void*)delegate;
	CFRetain(delegateKeepAlive);
	
	dispatch_block_t tidy = ^{
		CFRelease(delegateKeepAlive);
		dispatch_release(callingQueue);
	};
		
	delegate.success = ^{
		[socket synchronouslySetDelegateQueue:callingQueue];
		CPSocketConnection* connection = [[CPSocketConnection alloc] initWithSocket:socket];
		dispatch_async(callingQueue, ^{
			asyncResult(connection, nil);
			tidy();
		});
	};
	
	delegate.error = ^(NSError* error){
		asyncResult(nil, error);
		tidy();
	};
	
	NSError* error;
	if (![socket connectToAddress:address withTimeout:-1 error:&error]) {
		asyncResult(nil, error);
		tidy();
		return;
	}
}


#pragma mark - As a CPSocketConnection:

- (void) sendRawData:(NSData *)data
{
	[_socket writeData:CPSocketEncodeHeader(data, YES, NO) withTimeout:-1 tag:-1];
	[_socket writeData:data withTimeout:-1 tag:-1];
}

- (void) setDelegate:(id<CPSocketConnectionDelegate>)delegate
{
	_delegate = delegate;
	
	_delegateHas.raiseError = [delegate respondsToSelector:@selector(connection:didRaiseError:)];
	_delegateHas.receiveRaw = [delegate respondsToSelector:@selector(connection:didReceiveRawData:)];
	_delegateHas.receiveSecured = [delegate respondsToSelector:@selector(connection:didReceiveSecuredData:)];
	_delegateHas.secureData = [delegate respondsToSelector:@selector(connection:secureDataForTransmition:)];
	_delegateHas.didDisconnect = [delegate respondsToSelector:@selector(connectionDidDisconnect:)];
}



#pragma mark - As a CPConnection:

- (void) setPort:(CPPort *)port
{
	@synchronized(self) {
		_port = port;
		[_socket synchronouslySetDelegateQueue:[port queue]];
	}
}

- (CPPort*) port
{
	@synchronized(self) {
		return _port;
	}
}

- (void) sendPortMessageWithData:(NSData *)data
{
	@synchronized(self) {
		if (_delegateHas.secureData) {
			data = [_delegate connection:self secureDataForTransmition:data];
		}
	}
	
	[_socket writeData:CPSocketEncodeHeader(data, NO, _delegateHas.secureData) withTimeout:-1 tag:-1];
	[_socket writeData:data withTimeout:-1 tag:-1];
}

- (void)disconnect
{
    [self disconnect:NO];
}

- (void)disconnect:(BOOL)notifyPort
{	
	@synchronized(self) {
		[_socket synchronouslySetDelegate:nil];
		[_socket disconnect];
        
        if (notifyPort) {
            [_port connectionDidClose:self];
        }
        
        if (_delegateHas.didDisconnect) {
            [_delegate connectionDidDisconnect:self];
        }
		
		_port = nil;
		_socket = nil;
		_delegate = nil;
	}
}


#pragma mark - As a CGDAsyncSocketDelegate:

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	switch (tag) {
		case kCPSocketReadHeader: {
			BOOL isRaw, isSecured;
			NSUInteger payloadLength;
			
			if (!CPSocketDecodeHeader(data, &payloadLength, &isRaw, &isSecured)) {
				[self disconnectWithErrorCode:kCPSocketInvalidMessageError];
				break;
			}
			
			_currentMessage.isRaw = isRaw;
			_currentMessage.isSecured = isSecured;
			[sock readDataToLength:payloadLength withTimeout:-1 tag:kCPSocketReadPayload];
			
			break;
		}
			
		case kCPSocketReadPayload: {
			if (_currentMessage.isRaw) {
				NSAssert(_delegateHas.receiveRaw, @"Delegate must implement connection:didReceiveRawData: if raw data is sent.");
				[_delegate connection:self didReceiveRawData:data];
				[sock readDataToLength:kCPSocketHeaderSize withTimeout:-1 tag:kCPSocketReadHeader];
				break;
			}
			
			if (_currentMessage.isSecured) {
				NSAssert(_delegateHas.receiveSecured, @"Delegate must implement connection:didReceiveSecuredData: if secured data is sent.");
				data = [_delegate connection:self didReceiveSecuredData:data];
				if (!data) {
					if (_delegateHas.raiseError) {
						NSError* err = [NSError errorWithDomain:CPSocketErrorDomain
														   code:kCPSocketValidationFailedError
													   userInfo:nil];
						
						[_delegate connection:self didRaiseError:err];
					}
					
					[_socket readDataToLength:kCPSocketHeaderSize withTimeout:-1 tag:kCPSocketReadHeader];
					break;
				}
			}
			
			[_port connection:self didReceiveMessageWithData:data];
			[_socket readDataToLength:kCPSocketHeaderSize withTimeout:-1 tag:kCPSocketReadHeader];
			break;
		}
			
		default: {
			NSAssert(NO, @"Invalid tag");
			break;
		}
	}
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	BOOL connectionClosed = ([[err domain] isEqualToString:GCDAsyncSocketErrorDomain] &&
							 [err code] == GCDAsyncSocketClosedError);
	
	if (!connectionClosed && _delegateHas.raiseError) {
		[_delegate connection:self didRaiseError:err];
	}
    
    [self disconnect:YES];
}


#pragma mark - Private:

- (void) disconnectWithErrorCode:(NSInteger)code
{
	NSDictionary* userInfo = @{
		NSLocalizedDescriptionKey: NSLocalizedString(@"A fatal connection error occured", nil)
	};
	
	NSError* err = [NSError errorWithDomain:CPSocketErrorDomain code:code userInfo:userInfo];
	if (_delegateHas.raiseError) {
		[_delegate connection:self didRaiseError:err];
	}
	
	[self disconnect:YES];
}
				
@end

@implementation CPSocketConnectingDelegate

- (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	NSParameterAssert(_success);
	_success();
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSParameterAssert(_error);
	_error(err);
}

@end


NSString* const CPSocketErrorDomain = @"CPSocketErrorDomain";
