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

#import "CPRetainReleaseMessage.h"
#import "CPPort.h"
#import <objc/runtime.h>

@implementation CPRetainReference {
@public
	NSData* _id;
}

+ (NSArray*) keysForCoding
{
	return @[@"id"];
}

- (id) initWithID:(NSData *)remoteID
{
	self = [super init];
	if (!self)
		return nil;
	
	_id = remoteID;
	
	return self;
}

- (void) willSendOnPort:(CPPort *)port
{
	
}

- (void) didReceiveOnPort:(CPPort *)port
{
	[port retainingHandleForObject:_id];
}

@end


@implementation CPReleaseReference {
@public
	NSMutableArray* _ids;
}

static NSOperationQueue* GetCurrentReleaseQueue(void)
{
    return [NSOperationQueue currentQueue] ?: [NSOperationQueue mainQueue];
}

static CFMutableDictionaryRef GetCurrentReleaseMessageMap(void)
{
    NSOperationQueue* queue = GetCurrentReleaseQueue();
    
    @synchronized(queue) {
        static float mapKey;
        CFMutableDictionaryRef dict = (__bridge void*) objc_getAssociatedObject(queue, &mapKey);
        if (!dict) {
            dict = CFDictionaryCreateMutable(NULL, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            objc_setAssociatedObject(queue, &mapKey, (__bridge id)dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CFRelease(dict);
        }
        
        return dict;
    }
}

+ (void) releaseRemoteObjectWithID:(NSData *)remoteID viaPort:(CPPort *)port
{
    CFMutableDictionaryRef dict = GetCurrentReleaseMessageMap();
    
    @synchronized((__bridge id)dict) {
        CPReleaseReference* releaseMsg = (__bridge id) CFDictionaryGetValue(dict, (__bridge void*)port);
        if (!releaseMsg) {
            releaseMsg = [[self alloc] init];
            NSOperationQueue* queue = GetCurrentReleaseQueue();
            
            [queue addOperationWithBlock:^{
                @synchronized((__bridge id)dict) {
                    CFDictionaryRemoveValue(dict, (__bridge void*)port);
                }
                
                [port sendPortMessage:releaseMsg];
            }];
            
            CFDictionarySetValue(dict, (__bridge void*)port, (__bridge void*)releaseMsg);
        }
        
        [releaseMsg addID:remoteID];
    }
}

- (id) init
{
    self = [super init];
    if (!self)
        return nil;
    
    _ids = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) addID:(NSData*)remoteID
{
    [_ids addObject:remoteID];
}

+ (NSArray*) keysForCoding
{
	return @[@"ids"];
}

- (void) willSendOnPort:(CPPort *)port
{
	
}

- (void) didReceiveOnPort:(CPPort *)port
{
    for (NSData* localID in _ids) {
        [port releaseObjectWithHandle:localID];
    }
}

@end