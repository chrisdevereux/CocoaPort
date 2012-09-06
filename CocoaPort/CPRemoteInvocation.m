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

#import "CPRemoteInvocation.h"
#import "CPPortMessage.h"
#import "CPEvaluable.h"
#import "CPResponseMessage.h"


@implementation CPRemoteInvocation {
	CPMessageSend* _expr;
	CPResponseHandler _handler;
	NSData* _handlerId;
	BOOL _isCopy;
}

+ (NSArray*) keysForCoding
{
	return @[@"expr", @"handlerId", @"isCopy"];
}

- (id) initWithMessageSendExpression:(CPMessageSend *)expr responseHandler:(CPResponseHandler)handler copyResponse:(BOOL)copy
{
	self = [super init];
	if (!self)
		return nil;
	
	_expr = expr;
	_handler = handler;
	_isCopy = copy;
	
	return self;
}

- (void) willSendOnPort:(CPPort *)port
{
	_handlerId = _handler ? [port registerResponseHandler:_handler] : nil;
}

- (void) didReceiveOnPort:(CPPort *)port
{
	NSError* err;
	id result;
	
	if (![_expr evaluateWithPort:port result:&result error:&err]) {
		CPResponseMessage* msg = [[CPResponseMessage alloc] initWithValue:nil isCopy:YES error:err handlerID:_handlerId];
		[port sendPortMessage:msg];
		[port raiseError:err local:YES];
		return;
	}
	
	if (!_isCopy)
		result = [port retainingHandleForObject:result];
	
	CPResponseMessage* msg = [[CPResponseMessage alloc] initWithValue:result isCopy:_isCopy error:nil handlerID:_handlerId];
	[port sendPortMessage:msg];
		
}

@end

