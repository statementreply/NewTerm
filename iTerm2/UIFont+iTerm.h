//
//  NSFont+iTerm.h
//  iTerm
//
//  Created by George Nachman on 4/15/14.
//
//

@import UIKit;

@interface UIFont (iTerm)

// Encoded font name, suitable for storing in a profile.
@property(nonatomic, readonly) NSString *stringValue;

@end
