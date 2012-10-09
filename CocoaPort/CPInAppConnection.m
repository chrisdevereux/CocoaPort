//
//  CPInAppConnection.m
//  CocoaPort
//
//  Created by Chris Devereux on 09/10/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import "CPInAppConnection.h"
#import "CPPort.h"

@interface CPInAppConnection ()
@property (weak, nonatomic) CPInAppConnection* otherConnection;
@property (weak, nonatomic) CPPort* port;
@end


@implementation CPInAppConnection

+ (void) conection:(CPInAppConnection **)aConnection toConnection:(CPInAppConnection **)anotherConnection
{
    NSParameterAssert(aConnection);
    NSParameterAssert(anotherConnection);
    
    *aConnection = [[self alloc] init];
    *anotherConnection = [[self alloc] init];
    
    (*aConnection).otherConnection = *anotherConnection;
    (*anotherConnection).otherConnection = *aConnection;
}

- (void) sendPortMessageWithData:(NSData*)data
{
    [_otherConnection.port connection:_otherConnection didReceiveMessageWithData:data];
}

- (void) disconnect
{
    CPInAppConnection* other = _otherConnection;
    _otherConnection = nil;
    
    other.otherConnection = nil;
    
    [_port connectionDidClose:self];
    [other.port connectionDidClose:other];
}

@end
