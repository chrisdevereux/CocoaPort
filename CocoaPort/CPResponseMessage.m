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

#import <objc/runtime.h>
#import "CPResponseMessage.h"
#import "CPPort.h"
#import "CPFuture.h"

static NSMutableDictionary *s_encodersByType = nil;
static NSMutableDictionary *s_encodersByProtocol = nil;

@implementation CPResponseMessage {
	NSData* _handlerID;
	id _value;
	NSError* _err;
	BOOL _isCopy;
}

+ (NSArray*) keysForCoding
{
	return @[@"value", @"err", @"handlerID", @"isCopy"];
}

+ (void)registerEncoder:(Encoder)encoder forType:(Class)type {
	if (!s_encodersByType)
		s_encodersByType = [NSMutableDictionary dictionary];
	
	s_encodersByType[NSStringFromClass(type)] = encoder;
}

+ (void)registerEncoder:(Encoder)encoder forProtocol:(Protocol *)protocol {
	if (!s_encodersByProtocol)
		s_encodersByProtocol = [NSMutableDictionary dictionary];
	
	s_encodersByProtocol[NSStringFromProtocol(protocol)] = encoder;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	for (NSString* k in [[self class] keysForCoding]) {
		id obj = [self valueForKey:k];
		Encoder encoder = nil;
		
		for (NSString *c in s_encodersByType) {
			Class cls = NSClassFromString(c);
			
			if ([[obj class] isSubclassOfClass:cls])
				encoder = s_encodersByType[c];
		}

		if (!encoder) {
			for (NSString *p in s_encodersByProtocol) {
				if ([obj conformsToProtocol:NSProtocolFromString(p)]) {
					encoder = s_encodersByProtocol[p];
					break;
				}
			}
		}
		
		if (encoder)
			[aCoder encodeObject:encoder(obj) forKey:k];
		else
			[aCoder encodeObject:obj forKey:k];
	}
}

- (id) initWithValue:(id)value isCopy:(BOOL)isCopy error:(NSError *)err handlerID:(NSData *)handlerID
{
	self = [super init];
	if (!self)
		return nil;
	
	_value = value;
	_err = err;
	_handlerID = handlerID;
	_isCopy = isCopy;
	
	return self;
}

- (void) willSendOnPort:(CPPort *)port
{
	
}

- (void) didReceiveOnPort:(CPPort *)port
{
	CPResponseHandler handler = nil;
	
	if (_handlerID) {
		handler = [port lookupResponseHandler:_handlerID];
		[port removeResponseHandlerForID:_handlerID];
	}
	
	if (!handler)
		return;
	
	if (_err) {
		handler(nil, _err);
		return;
	}
	
	if (_isCopy) {
		handler(_value, nil);
	} else {
		id future = [CPRemoteReferenceFuture futureWithPort:port target:_value];
		handler(future, nil);
	}
}

@end