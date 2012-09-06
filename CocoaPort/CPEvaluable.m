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

#import "CPEvaluable.h"
#import "CPPort.h"
#import "CPFuture.h"

@implementation CPObjectValue

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
		return nil;
	
	_value = [aDecoder decodeObjectForKey:@"v"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_value forKey:@"v"];
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	*resultPtr = _value;
	return YES;
}

@end


@implementation CPObjectReference

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
	return nil;
	
	_id = [aDecoder decodeObjectForKey:@"v"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_id forKey:@"v"];
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	*resultPtr = [port objectForHandle:_id];
	if (*resultPtr)
		return YES;
	
	*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPPortBadReference userInfo:@{ @"id" : _id }];
	return NO;
}

@end


@implementation CPRemotePortReference

- (id) initWithCoder:(NSCoder *)aDecoder
{
	return [self init];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError *__autoreleasing *)err
{
	*resultPtr = port;
	return YES;
}

@end


@implementation CPRootObjectReference

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
		return nil;
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	*resultPtr = [port rootObject];
	return YES;
}

@end


@implementation CPMessageSend

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
	return nil;
	
	_args = [aDecoder decodeObjectForKey:@"a"];
	_target = [aDecoder decodeObjectForKey:@"t"];
	_sel = [aDecoder decodeObjectForKey:@"s"];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_args forKey:@"a"];
	[aCoder encodeObject:_target forKey:@"t"];
	[aCoder encodeObject:_sel forKey:@"s"];
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	id target;
	if (![_target evaluateWithPort:port result:&target error:err])
		return NO;
	
	SEL selector = NSSelectorFromString(_sel);
	
	NSMethodSignature* sig = [target methodSignatureForSelector:selector];
	if (!sig) {
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgNoKnownMethod userInfo:@{@"selector": _sel}];
		return NO;
	}
	if ([sig numberOfArguments] - 2 != [_args count]) {
		NSDictionary* userInfo = @{
			@"sel": _sel,
			@"expected": @([sig numberOfArguments]-2),
			@"actual": @([_args count])
		};
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgSignatureMismatch userInfo:userInfo];
		return NO;
	}
	for (NSUInteger i = 0 ; i < [_args count]; i++) {
		const char* t = [sig getArgumentTypeAtIndex:i + 2];
		if (strcmp(t, @encode(id)) != 0) {
			NSDictionary* userInfo = @{
				@"sel": _sel,
				@"typeEncoding": @(t)
			};
			*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgInvalidArgumentType userInfo:userInfo];
			return NO;
		}
	}
	const char* rt = [sig methodReturnType];
	if (strcmp(rt, @encode(id)) != 0 && strcmp(rt, @encode(void)) != 0 && strcmp(rt, @encode(Class)) != 0) {
		NSDictionary* userInfo = @{
			@"sel": _sel,
			@"typeEncoding": @(rt)
		};
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgInvalidReturnType userInfo:userInfo];
		return NO;
	}
	
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
	NSUInteger idx = 2;
	for (id<CPEvaluable> a in _args) {
		id arg;
		if (![a evaluateWithPort:port result:&arg error:err]) {
			return NO;
		}
		[inv setArgument:&arg atIndex:idx];
		idx++;
	}
	
	[inv setSelector:selector];
	
	@try {
		[inv invokeWithTarget:target];
	}
	@catch (NSException* ex) {
		NSDictionary* userInfo = @{
			@"sel": _sel,
			@"ex": ex
		};
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgExceptionRaised userInfo:userInfo];
		return NO;
	}
	@catch (id ex) {
		NSDictionary* userInfo = @{
			@"sel": _sel,
			@"exDesc": [ex description]
		};
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgExceptionRaised userInfo:userInfo];
		return NO;
	}
	@catch (...) {
		NSDictionary* userInfo = @{
			@"sel": _sel
		};
		*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPInvokeMsgExceptionRaised userInfo:userInfo];
		return NO;
	}
	
	if (strcmp([sig methodReturnType], @encode(void)) == 0) {
		*resultPtr = nil;
	} else {
		__unsafe_unretained id value;
		[inv getReturnValue:&value];
		*resultPtr = value;
	}
	
	return YES;
}

@end


@implementation CPClassRef

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
	return nil;
	
	_name = [aDecoder decodeObjectForKey:@"n"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_name forKey:@"n"];
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	*resultPtr = NSClassFromString(_name);
	if (*resultPtr) {
		return YES;
	}
	
	*err = [NSError errorWithDomain:CPPortErrorDomain code:kCPPortBadReference userInfo:@{@"class": _name}];
	return NO;
}

@end


@implementation CPProxyReference

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
		return nil;
	
	_id = [aDecoder decodeObjectForKey:@"i"];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_id forKey:@"i"];
}

- (BOOL) evaluateWithPort:(CPPort *)port result:(__autoreleasing id *)resultPtr error:(NSError**)err
{
	*resultPtr = [CPRemoteReferenceFuture futureWithPort:port target:_id];
	return YES;
}

@end
