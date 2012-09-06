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

#import "CPCodingObject.h"
#import <objc/runtime.h>

@implementation CPCodingObject

static float kCPKeyList;

+ (NSArray*) keysForCoding
{
	NSMutableArray* keys = objc_getAssociatedObject(self, &kCPKeyList);
	if (keys)
		return keys;
	
	unsigned count;
	objc_property_t* properties = class_copyPropertyList([self class], &count);
	
	keys = [[NSMutableArray alloc] initWithCapacity:count];
	
	for (unsigned i = 0 ; i < count; i++) {
		const char* name = property_getName(properties[i]);
		[keys addObject:[NSString stringWithUTF8String:name]];
	}
	
	free(properties);
	
	objc_setAssociatedObject(self, &kCPKeyList, keys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return keys;
}


- (void) encodeWithCoder:(NSCoder *)aCoder
{
	for (NSString* k in [[self class] keysForCoding]) {
		[aCoder encodeObject:[self valueForKey:k] forKey:k];
	}
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
		return nil;
	
	for (NSString* k in [[self class] keysForCoding]) {
		[self setValue:[aDecoder decodeObjectForKey:k] forKey:k];
	}
	
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	return self;
}


@end
