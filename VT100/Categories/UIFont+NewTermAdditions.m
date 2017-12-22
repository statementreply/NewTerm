#import "UIFont+NewTermAdditions.h"

@implementation UIFont (NewTermAdditions)

+ (instancetype)fallbackFixedPitchFontOfSize:(CGFloat)size {
	return [self fontWithName:@"Courier" size:size == 0 ? [self systemFontSize] : size];
}

@end
