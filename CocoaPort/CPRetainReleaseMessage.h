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
#import "CPPortMessage.h"
#import "CPCodingObject.h"

@interface CPRetainReference : CPCodingObject <CPPortMessage>

- (id) initWithID:(NSData*)remoteID;

@end

@interface CPReleaseReference : CPCodingObject <CPPortMessage>

/**
 Sends a release message for _remoteID_ over _port_.
 
 The message is not sent immediately, as for efficiency reasons, all release 
 requests in a cycle of the event loop are aggregated into a single message, 
 which is sent once the cycle completes.
 
 If called from a dispatch queue when no requests are queued, a block to send
 the release message is posted to the curent queue, and any following requests
 are added to that message.
 
 If called from any other thread, the release request is treated as if it came
 from the main queue.
*/
 
+ (void) releaseRemoteObjectWithID:(NSData*)remoteID viaPort:(CPPort*)port;

@end
