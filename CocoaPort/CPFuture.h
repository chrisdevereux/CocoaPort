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


@interface CPFuture : NSProxy
+ (id) futureWithPort:(CPPort*)port;
@end


@interface CPRootObjectReferenceFuture : CPFuture
@end


@interface CPRemotePortReferenceFuture : CPFuture
@end


@interface CPInvocationFuture : CPFuture
+ (id) futureWithPort:(CPPort*)port targetExpression:(id)target selector:(SEL)selector args:(NSArray*)args;
@end 


@interface CPRemoteReferenceFuture : CPFuture
+ (id) futureWithPort:(CPPort*)port target:(NSData*)target;
@end


@interface CPLocalObjectReferenceFuture : CPFuture
+ (id) futureWithPort:(CPPort *)port localObject:(id)local;
@end


@interface CPNilFuture : CPFuture
@end


@interface CPClassReferenceFuture : CPFuture
+ (id) futureWithPort:(CPPort *)port className:(id)className;
@end


OBJC_EXPORT id<CPEvaluable> CPConvertFutureExpressionToEvaluable(id futureExpression);
