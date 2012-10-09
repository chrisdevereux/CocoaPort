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

@protocol CPEvaluable;
@class CPPort;


/**
 Semi-abstract base class for futures.
 
 CPFuture provides a common implementation of -forwardInvocation, which 
 (unless overridden) returns a CPInvocationFuture representing the method invocation.
*/

@interface CPFuture : NSProxy
+ (id) futureWithPort:(CPPort*)port;
@end


/**
 Represents the root object of the remote port.
*/

@interface CPRootObjectReferenceFuture : CPFuture
@end


/**
 Represents the remote port. Used to implement higher-level CPPort features.
*/

@interface CPRemotePortReferenceFuture : CPFuture
@end


/**
 Represents a method invocation.
*/

@interface CPInvocationFuture : CPFuture
+ (id) futureWithPort:(CPPort*)port targetExpression:(id)target selectorName:(NSString*)selectorName args:(NSArray*)args;
@end


/**
 Reference to a remote object.
 
 Deallocating a CPRemoteReferenceFuture results in a CPRetainMessage being sent over _port_
 to release the referenced object.
*/

@interface CPRemoteReferenceFuture : CPFuture
+ (id) futureWithPort:(CPPort*)port target:(NSData*)target;
@end


/**
 Returned by [CPPort reference:].
 
 Messages are forwarded to _localObject_, with the result returned as a CPLocalObjectReferenceFuture.
 
 Never sent over a port -- received as a CPRemoteReferenceFuture.
*/

@interface CPLocalObjectReferenceFuture : CPFuture
+ (id) futureWithPort:(CPPort *)port localObject:(id)local;
@end


/**
 Converted to actual nil when received by a port.
*/

@interface CPNilFuture : CPFuture
@end


/**
 Converts a future to an object suitable for encoding, sending over the port and
 being evaluated by the remote port.
*/

OBJC_EXPORT id<CPEvaluable> CPConvertFutureExpressionToEvaluable(id futureExpression);
