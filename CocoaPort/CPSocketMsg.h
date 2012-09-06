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

struct __attribute__ ((packed))
CPSocketMsgHeader {
	uint16_t magic;
	uint32_t size;
	
	struct {
		uint8_t rawData :1;
		uint8_t secured :1;
	} flags;
};


#define kMAGIC 0xC0C0

static NSData* CPSocketEncodeHeader(NSData* payload, BOOL rawData, BOOL secured)
{
	NSCAssert([payload length] <= UINT32_MAX, @"Message is too big!");
	
	struct CPSocketMsgHeader header;
	header.magic = CFSwapInt16HostToLittle(kMAGIC);
	header.size = CFSwapInt32HostToLittle((uint32_t)[payload length]);
	header.flags.rawData = rawData;
	header.flags.secured = secured;
	
	return [NSData dataWithBytes:&header length:sizeof(header)];
}


static BOOL CPSocketDecodeHeader(NSData* headerData, NSUInteger* payloadSizeOut, BOOL* rawDataOut, BOOL* securedOut)
{
	struct CPSocketMsgHeader header;
	if ([headerData length] != sizeof(header))
		return NO;
	
	[headerData getBytes:&header length:sizeof(header)];
	if (CFSwapInt16LittleToHost(header.magic) != kMAGIC)
		return NO;
	
	*payloadSizeOut = CFSwapInt32LittleToHost(header.size);
	*rawDataOut = header.flags.rawData;
	*securedOut = header.flags.secured;
	
	return YES;
}

static const NSUInteger kCPSocketHeaderSize = sizeof(struct CPSocketMsgHeader);
