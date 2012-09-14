//
//  CPNilPlaceholder.h
//  CocoaPort
//
//  Created by Chris Devereux on 14/09/2012.
//  Copyright (c) 2012 Chris Devereux. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPEvaluable.h"

@interface CPNilPlaceholder : NSObject <CPEvaluable>

+ (instancetype) nilPlaceholder;

@end
