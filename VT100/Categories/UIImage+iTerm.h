//
//  NSImage+iTerm.h
//  iTerm
//
//  Created by George Nachman on 7/20/14.
//
//

@interface UIImage (iTerm)

// Returns "gif", "png", etc., or nil.
+ (NSString *)extensionForUniformType:(NSString *)type;

// Recolor the image with the given color but preserve its alpha channel.
- (instancetype)imageWithColor:(UIColor *)color;

@end
