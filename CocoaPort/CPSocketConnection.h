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

#import "CPConnection.h"

@class GCDAsyncSocket;
@protocol CPSocketConnectionDelegate;

@interface CPSocketConnection : NSObject <CPConnection>

@property (unsafe_unretained, nonatomic) id<CPSocketConnectionDelegate> delegate;

/**
 
 Creates a GCDAsyncSocket, connects to _address_, and returns a via _asyncResult_
 a connection created by calling initWithSocket:, or an error if the connection
 was not sucessful.
 
 Callbacks from the connection will be made on the dispatch queue that this method
 is called from.
*/

+ (void) connectToAddress:(NSData*)address
				  timeout:(NSTimeInterval)timeout
			  asyncResult:(void(^)(id connection, NSError*error))asyncResult;


/**
 Designated initializer.
 
 _socket_ should be connected to a remote CPSocketPort. Note that this is a blocking call.
 The socket's current delegate queue is respected, but the delegate is set to the receiver.
*/
- (id) initWithSocket:(GCDAsyncSocket*)socket;


/**
 Sends _data_, bypassing delegate methods such as connection:secureDataForTransmition:.
 
 On recipt, the data is send to the delegate method connection:didReceiveRawData:, rather
 than to CPPort. This provides a mechanism for implementing a custom handshake before
 passing control to CPPort. CPPort may be nil when this method is called.
 
 _data_ must not be nil, and must have a length greater than zero.
*/
- (void) sendRawData:(NSData*)data;

@end


/**
 @important
 When a connection is bound to a CPPort, delegate callbacks will be made on the
 port's queue. When a connection is not bound, delegates callbacks will be made 
 on a concurrent queue.
*/

@protocol CPSocketConnectionDelegate <NSObject>
@optional

/**
 Called on receipt of data sent using [CPSocketConnection sendRawData:]
*/
- (void) connection:(CPSocketConnection*)connection didReceiveRawData:(NSData*)data;


/**
 Sends the return value over the socket instead of _data_.
 
 Provided to allow custom encryption and verification.
*/
- (NSData*) connection:(CPSocketConnection*)connection secureDataForTransmition:(NSData*)data;


/**
 Sends the return value to CPPort instead of _data_
 
 Provided to allow custom encryption and verification.

 Returning nil will cause the connection to raise a verification error.
*/
- (NSData*) connection:(CPSocketConnection*)connection didReceiveSecuredData:(NSData*)data;


/**
 Called to indicate a connectivity or security error.
 */
- (void) connection:(CPSocketConnection*)connection didRaiseError:(NSError*)error;


/**
 Called when the connection disconnects.
 */
- (void) connectionDidDisconnect:(CPSocketConnection*)connection;

@end


OBJC_EXPORT NSString* const CPSocketErrorDomain;

enum {
	kCPSocketInvalidMessageError,
	kCPSocketValidationFailedError
};
