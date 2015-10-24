//
//  NSFont+iTerm.m
//  iTerm
//
//  Created by George Nachman on 4/15/14.
//
//

#import "UIFont+iTerm.h"

@implementation UIFont (iTerm)

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"%@ %g", [self fontName], [self pointSize]];
}

@end
