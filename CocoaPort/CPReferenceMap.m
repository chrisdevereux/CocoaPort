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

#import "CPReferenceMap.h"

@interface CPReferenceMapRecord : NSObject
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSData* uuid;
@property (assign, nonatomic) NSUInteger count;
@end

@implementation CPReferenceMapRecord
@end



@implementation CPReferenceMap {
	CFMutableDictionaryRef _uidMapped;
	CFMutableDictionaryRef _objectMapped;
}


static NSData* GenerateUID(void)
{
	uuid_t bytes;
	uuid_generate_time(bytes);
	return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}


- (id) init
{
	self = [super init];
	if (!self)
		return nil;
	
	_uidMapped = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	_objectMapped = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	return self;
}


- (void) dealloc
{
	if (_objectMapped) {
		CFRelease(_objectMapped);
	}
	
	if (_uidMapped) {
		CFRelease(_uidMapped);
	}
}


- (NSData*) referenceObject:(id)object
{
	if (!object)
		return [NSData data];
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_objectMapped, (__bridge void*) object);
	if (val) {
		val.count++;
		return val.uuid;
	}
	
	val = [[CPReferenceMapRecord alloc] init];
	
	uuid_t uuidBytes;
	uuid_generate_time(uuidBytes);
	NSData* uidData = [NSData dataWithBytes:uuidBytes length:sizeof(uuidBytes)];
	
	val.object = object;
	val.count = 1;
	val.uuid = uidData;
	
	CFDictionarySetValue(_uidMapped, (__bridge void*)val.uuid, (__bridge void*) val);
	CFDictionarySetValue(_objectMapped, (__bridge void*)object, (__bridge void*) val);
	
	return uidData;
}


- (void) releaseObject:(id)object
{
	if (!object)
		return;
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_objectMapped, (__bridge void*) object);
	if (!val)
		return;
	
	if (val.count != 1) {
		val.count--;
		return;
	}
	
	CFDictionaryRemoveValue(_uidMapped, (__bridge void*) val.uuid);
	CFDictionaryRemoveValue(_objectMapped, (__bridge void*) val.object);
}


- (void) referenceObjectWithUID:(NSData*)uid
{
	if ([uid length] == 0)
		return;
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_uidMapped, (__bridge void*) uid);
	if (!val)
		return;
	
	val.count++;
}


- (void) releaseObjectWithUID:(NSData*)uid
{
	if ([uid length] == 0)
		return;
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_uidMapped, (__bridge void*) uid);
	if (!val)
		return;
	
	if (val.count != 1) {
		val.count--;
		return;
	}
	
	CFDictionaryRemoveValue(_uidMapped, (__bridge void*) uid);
	CFDictionaryRemoveValue(_objectMapped, (__bridge void*) val.object);
}


- (NSData*) uidForObject:(id)object
{
	if (!object)
		return [NSData data];
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_objectMapped, (__bridge void*) object);
	if (!val)
		return nil;
	
	return val.uuid;
}


- (id) objectForUID:(NSData*)uid
{
	if ([uid length] == 0)
		return nil;
	
	CPReferenceMapRecord* val = CFDictionaryGetValue(_uidMapped, (__bridge void*) uid);
	if (!val)
		return nil;
	
	return val.object;
}


static void BlockEnumerateUIDMap(const void* k, const void* v, void* ctx)
{
	void (^block)(NSData*, id) = (__bridge id) ctx;
	NSData* uid = (__bridge id) k;
	CPReferenceMapRecord* record = (__bridge id) v;
	
	block(uid, record.object);
}


- (void) enumerateObjectsUsingBlock:(void (^)(NSData*, id))block
{
	NSParameterAssert(block);
	
	CFDictionaryRef copy = CFDictionaryCreateCopy(NULL, _uidMapped);
	CFDictionaryApplyFunction(copy, BlockEnumerateUIDMap, (__bridge void*)block);
	CFRelease(copy);
}


@end
