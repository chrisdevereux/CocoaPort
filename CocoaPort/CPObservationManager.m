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

#import "CPObservationManager.h"

@interface CPObservationInfo : NSObject

@property (strong, nonatomic) id observedObject;
@property (copy, nonatomic) NSString* observedKeypath;
@property (copy, nonatomic) NSData* uid;
@property (copy, nonatomic) void(^changeBlock)(id change);

@end


@implementation CPObservationManager {
	NSMutableDictionary* _objectKeypathMapped;
	NSMutableDictionary* _uidMapped;
}


static id KeyForObjectAndKeypath(id object, NSString* keypath)
{
	return @[object, keypath];
}


- (id) init
{
	self = [super init];
	if (!self)
		return nil;
	
	_objectKeypathMapped = [[NSMutableDictionary alloc] init];
	_uidMapped = [[NSMutableDictionary alloc] init];
	
	return self;
}


- (void) dealloc
{
	[self removeAllObservers];
}


- (void) removeAllObservers
{
    NSArray* observed;
    
	@synchronized(self){
        observed = [_objectKeypathMapped allValues];
	}
    
    for (CPObservationInfo* info in observed) {
        [info.observedObject removeObserver:self forKeyPath:info.observedKeypath];
    }
}


- (void) addObserverForObject:(id)object keyPath:(NSString *)keypath uid:(NSData *)uid usingBlock:(void(^)(id change))block
{
    if (!object)
        return;
    
	CPObservationInfo* info = [[CPObservationInfo alloc] init];
	info.observedObject = object;
	info.observedKeypath = keypath;
	info.uid = uid;
	info.changeBlock = block;
	
	@synchronized(self){
		[_objectKeypathMapped setObject:info forKey:KeyForObjectAndKeypath(object, keypath)];
		[_uidMapped setObject:info forKey:uid];
	}
		
    NSKeyValueObservingOptions opts = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;
    [object addObserver:self forKeyPath:keypath options:opts context:(__bridge void*)self];
}


- (void) removeObserverWithUID:(NSData *)uid
{
    if (!uid)
        return;
    
    CPObservationInfo* info;
    
	@synchronized(self){
		info = [_uidMapped objectForKey:uid];
        
        if (!info)
            return;
        
        [_objectKeypathMapped removeObjectForKey:KeyForObjectAndKeypath(info.observedObject, info.observedKeypath)];
        [_uidMapped removeObjectForKey:info.uid];
    }
    
    [info.observedObject removeObserver:self forKeyPath:info.observedKeypath];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context != (__bridge void*) self) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
    
    CPObservationInfo* info;
	
	@synchronized(self){
		info = [_objectKeypathMapped objectForKey:KeyForObjectAndKeypath(object, keyPath)];
        
		if (!info)
			return;
	}

    info.changeBlock([change objectForKey:NSKeyValueChangeNewKey]);
}

@end


@implementation CPObservationInfo
@end
