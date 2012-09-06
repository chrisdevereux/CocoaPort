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

@class CPPort;
@class CPInvocationFuture;
@class NSError;

@protocol CPEvaluable <NSObject, NSCoding>
- (BOOL) evaluateWithPort:(CPPort*)port result:(id*)resultPtr error:(NSError**)err;
@end


@interface CPObjectValue : NSObject <CPEvaluable> {
@public
	id<NSCoding> _value;
}
@end

@interface CPObjectReference : NSObject <CPEvaluable> {
@public
	NSData* _id;
}
@end

@interface CPProxyReference : NSObject <CPEvaluable> {
@public
	NSData* _id;
}

@end

@interface CPRootObjectReference : NSObject <CPEvaluable>
@end

@interface CPRemotePortReference : NSObject <CPEvaluable>
@end

@interface CPMessageSend : NSObject <CPEvaluable> {
@public
	NSArray* _args;
	NSString* _sel;
	id<CPEvaluable> _target;
}
@end

@interface CPClassRef : NSObject <CPEvaluable>{
@public
	NSString* _name;
}
@end