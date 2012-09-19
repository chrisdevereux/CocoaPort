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

#import "CPFuture.h"
#import "CPConnection.h"
#import "CPPort.h"
#import "CPRetainReleaseMessage.h"
#import "CPEvaluable.h"
#import "CPNilPlaceholder.h"
#import <objc/runtime.h>

#pragma mark - Method prototypes:

@interface CPMessageFuturePrototypes : NSObject
@end
@implementation CPMessageFuturePrototypes

static NSArray* methodSignatures;

-(id) _isp_prototype { return nil; }
-(id) _isp_prototype:(id)arg0  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5 :(id)arg6  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5 :(id)arg6 :(id)arg7  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5 :(id)arg6 :(id)arg7 :(id)arg8  { return nil; }
-(id) _isp_prototype:(id)arg0 :(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5 :(id)arg6 :(id)arg7 :(id)arg8 :(id)arg9  { return nil; }

+ (void) load
{
	NSMutableArray* sigs = [[NSMutableArray alloc] initWithCapacity:10 + 1];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype:)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype:::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype:::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype::::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype:::::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype::::::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype:::::::::)]];
	[sigs addObject:[CPMessageFuturePrototypes instanceMethodSignatureForSelector:@selector(_isp_prototype::::::::::)]];
	methodSignatures  = sigs;
}

@end



#pragma mark - Message forwarding:

@implementation CPFuture {
@protected
	CPPort* _port;
}

+ (id) futureWithPort:(CPPort *)port
{
	CPFuture* b = [self alloc];
	b->_port = port;
	return b;
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
	size_t numArgs = 0;
	const char* selName = sel_getName(sel);
	
	for (selName = strchr(selName, ':'); selName; selName = strchr(selName, ':')) {
		selName++;
		numArgs++;
	}
	
	NSAssert(numArgs <= 10, @"too many arguments to message %s. max allowed = 10", sel_getName(sel));
	return [methodSignatures objectAtIndex:numArgs];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
	NSMethodSignature* sig = [invocation methodSignature];
	NSUInteger numArgs = [sig numberOfArguments] - 2;
	NSMutableArray* args = [[NSMutableArray alloc] initWithCapacity:numArgs];
	
	for (NSUInteger i = 0 ; i < numArgs; i++) {
		__unsafe_unretained id a;
		[invocation getArgument:&a atIndex:i + 2];
		[args addObject:a ?: [CPNilFuture futureWithPort:_port]];
	}
	
	CPInvocationFuture* future = [CPInvocationFuture futureWithPort:_port 
													   targetExpression:self
															   selector:[invocation selector] 
																   args:args];
	[invocation setReturnValue:&future];
}

@end


@implementation CPRemotePortReferenceFuture

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPRemoteReferenceFuture *)future
{
	return [[CPRemotePortReference alloc] init];
}

@end



@implementation CPRemoteReferenceFuture {
@protected
	NSData* _target;
}

+ (id) futureWithPort:(CPPort*)port target:(NSData*)target
{
	CPRemoteReferenceFuture* future = [super futureWithPort:port];
	future->_target = target;
	
	[port sendPortMessage:[[CPRetainReference alloc] initWithID:target]];
	return future;
}

- (void) dealloc
{
	[_port sendPortMessage:[[CPReleaseReference alloc] initWithID:_target]];
}

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPRemoteReferenceFuture *)future
{
	CPObjectReference* expr = [CPObjectReference new];
	expr->_id = future->_target;
	return expr;
}

@end



@implementation CPInvocationFuture {
@protected
	NSArray* _args;
	NSString* _sel;
	id _targetExpr;
}

+ (id) futureWithPort:(CPPort*)port targetExpression:(id)target selector:(SEL)selector args:(NSArray*)args
{
	CPInvocationFuture* future = [super futureWithPort:port];
	future->_args = args;
	future->_sel = NSStringFromSelector(selector);
	future->_targetExpr = target;
	return future;
}

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPInvocationFuture *)future
{
	CPMessageSend* expr = [CPMessageSend new];
	
	NSMutableArray* exprArgs = [NSMutableArray arrayWithCapacity:[future->_args count]];
	
	for (id a in future->_args) {
		[exprArgs addObject:CPConvertFutureExpressionToEvaluable(a)];
	}
	
	expr->_args = exprArgs;
	expr->_sel = [future->_sel copy];
	expr->_target = CPConvertFutureExpressionToEvaluable(future->_targetExpr);
	return expr;
}

@end



@implementation CPRootObjectReferenceFuture

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPFuture *)future
{
	return [CPRootObjectReference new];
}

@end



@implementation CPLocalObjectReferenceFuture {
@protected
	id _local;
}

+ (id) futureWithPort:(CPPort *)port localObject:(id)local
{
	CPLocalObjectReferenceFuture* future = [self futureWithPort:port];
	if (!future)
		return nil;
	
	future->_local = local;
	return future;
}

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPLocalObjectReferenceFuture *)future
{
	CPProxyReference* ref = [CPProxyReference new];
	if (!ref)
		return nil;
	
	ref->_id = [future->_port retainingHandleForObject:future->_local];
	
	return ref;
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	NSMethodSignature* sig = [invocation methodSignature];
	
	if (strcmp([sig methodReturnType], @encode(id)) != 0) {
		NSString* selName = NSStringFromSelector([invocation selector]);
		[NSException raise:NSInvalidArgumentException format:@"Methods called on proxy expressions must return id. %@ does not", selName];
	}
	
	[invocation invokeWithTarget:_local];
	id returnValue;
	[invocation getReturnValue:&returnValue];
	returnValue = [CPLocalObjectReferenceFuture futureWithPort:_port localObject:returnValue];
	[invocation setReturnValue:&returnValue];
}

@end


@implementation CPClassReferenceFuture {
@protected
	NSString* _name;
}

+ (id) futureWithPort:(CPPort *)port className:(id)className
{
	CPClassReferenceFuture* future = [super futureWithPort:port];
	if (!future)
		return nil;
	
	future->_name = className;
	return future;
}

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPClassReferenceFuture *)future
{
	CPClassRef* ref = [CPClassRef new];
	if (!ref)
		return nil;
	
	ref->_name = future->_name;
	return ref;
}

@end


@implementation CPNilFuture

+ (id<CPEvaluable>) convertFutureToInvocationExpression:(CPNilFuture *)future
{
    return [CPNilPlaceholder nilPlaceholder];
}

@end


// When when we convert the future proxies into the actual expression objects we're going to send,
// we want polymorphism to deal with the different types, but can't really define a 'convert' instance
// method in each future class in case we're proxying an object with a 'convert' method of its own.
// To get around this, we use class methods (which aren't availible to the user) as a private namespace
// for our conversion methods.
					 
id<CPEvaluable> CPConvertFutureExpressionToEvaluable(id object)
{
	Class cls = object_getClass(object);
	Class metaclass = object_getClass(cls);
	
	if (class_respondsToSelector(metaclass, @selector(convertFutureToInvocationExpression:))) {
		return [cls convertFutureToInvocationExpression:object];
	}
	
	CPObjectValue* expr = [CPObjectValue new];
	expr->_value = object;
	return expr;
}

