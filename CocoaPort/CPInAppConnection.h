//
//  CPInAppConnection.h
//  CocoaPort
//
//  Created by Chris Devereux on 09/10/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPConnection.h"

@interface CPInAppConnection : NSObject <CPConnection>

+ (void) conection:(CPInAppConnection**)aConnection toConnection:(CPInAppConnection**)anotherConnection;

@end
