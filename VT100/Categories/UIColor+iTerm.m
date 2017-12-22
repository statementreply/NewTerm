//
//  UIColor+iTerm.m
//  iTerm
//
//  Created by George Nachman on 3/2/14.
//
//

#import "UIColor+iTerm.h"

// Constants for converting RGB to luma.
static const double kRedComponentBrightness = 0.30;
static const double kGreenComponentBrightness = 0.59;
static const double kBlueComponentBrightness = 0.11;

NSString *const kEncodedColorDictionaryRedComponent = @"Red Component";
NSString *const kEncodedColorDictionaryGreenComponent = @"Green Component";
NSString *const kEncodedColorDictionaryBlueComponent = @"Blue Component";
NSString *const kEncodedColorDictionaryAlphaComponent = @"Alpha Component";
NSString *const kEncodedColorDictionaryColorSpace = @"Color Space";
NSString *const kEncodedColorDictionarySRGBColorSpace = @"sRGB";
NSString *const kEncodedColorDictionaryCalibratedColorSpace = @"Calibrated";

CGFloat PerceivedBrightness(CGFloat r, CGFloat g, CGFloat b) {
    return (kRedComponentBrightness * r +
            kGreenComponentBrightness * g +
            kBlueComponentBrightness * b);
}

@implementation UIColor (iTerm)

+ (instancetype)colorWithString:(NSString *)s {
    if ([s hasPrefix:@"#"] && s.length == 7) {
        return [self colorFromHexString:s];
    }
    NSData *data = [[[NSData alloc] initWithBase64EncodedString:s options:0] autorelease];
    if (!data.length) {
        return nil;
    }
    @try {
        NSKeyedUnarchiver *decoder = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];
        UIColor *color = [[[UIColor alloc] initWithCoder:decoder] autorelease];
        return color;
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to decode color from string %@", s);
        return nil;
    }
}

- (NSString *)stringValue {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *coder = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    coder.outputFormat = NSPropertyListBinaryFormat_v1_0;
    [self encodeWithCoder:coder];
    [coder finishEncoding];
    return [data base64EncodedStringWithOptions:0];
}

+ (instancetype)colorWith8BitRed:(int)red
                        green:(int)green
                         blue:(int)blue {
    return [UIColor colorWithRed:red / 255.0
                               green:green / 255.0
                                blue:blue / 255.0
                               alpha:1];
}

+ (instancetype)colorWith8BitRed:(int)red
                        green:(int)green
                         blue:(int)blue
                       muting:(double)muting
                backgroundRed:(CGFloat)bgRed
              backgroundGreen:(CGFloat)bgGreen
               backgroundBlue:(CGFloat)bgBlue {
    CGFloat r = (red / 255.0) * (1 - muting) + bgRed * muting;
    CGFloat g = (green / 255.0) * (1 - muting) + bgGreen * muting;
    CGFloat b = (blue / 255.0) * (1 - muting) + bgBlue * muting;

    return [UIColor colorWithRed:r
                               green:g
                                blue:b
                               alpha:1];
}

+ (void)getComponents:(CGFloat *)result
      forColorWithRed:(CGFloat)r
                green:(CGFloat)g
                 blue:(CGFloat)b
                alpha:(CGFloat)a
  perceivedBrightness:(CGFloat)t {
    /*
     Given:
     a vector c [c1, c2, c3] (the starting color)
     a vector e [e1, e2, e3] (an extreme color we are moving to, normally black or white)
     a vector A [a1, a2, a3] (the perceived brightness transform)
     a linear function f(Y)=AY (perceived brightness for color Y)
     a constant t (target perceived brightness)
     find a vector X such that F(X)=t
     and X lies on a straight line between c and e
     
     Define a parametric vector x(p) = [x1(p), x2(p), x3(p)]:
     x1(p) = p*e1 + (1-p)*c1
     x2(p) = p*e2 + (1-p)*c2
     x3(p) = p*e3 + (1-p)*c3
     
     when p=0, x=c
     when p=1, x=e
     
     the line formed by x(p) from p=0 to p=1 is the line from c to e.
     
     Our goal: find the value of p where f(x(p))=t
     
     We know that:
     [x1(p)]
     f(X) = AX = [a1 a2 a3] [x2(p)] = a1x1(p) + a2x2(p) + a3x3(p)
     [x3(p)]
     Expand and solve for p:
     t = a1*(p*e1 + (1-p)*c1) + a2*(p*e2 + (1-p)*c2) + a3*(p*e3 + (1-p)*c3)
     t = a1*(p*e1 + c1 - p*c1) + a2*(p*e2 + c2 - p*c2) + a3*(p*e3 + c3 - p*c3)
     t = a1*p*e1 + a1*c1 - a1*p*c1 + a2*p*e2 + a2*c2 - a2*p*c2 + a3*p*e3 + a3*c3 - a3*p*c3
     t = a1*p*e1 - a1*p*c1 + a2*p*e2 - a2*p*c2 + a3*p*e3 - a3*p*c3 + a1*c1 + a2*c2 + a3*c3
     t = p*(a2*e1 - a1*c1 + a2*e2 - a2*c2 + a3*e3 - a3*c3) + a1*c1 + a2*c2 + a3*c3
     t - (a1*c1 + a2*c2 + a3*c3) = p*(a1*e1 - a1*c1 + a2*e2 - a2*c2 + a3*e3 - a3*c3)
     p = (t - (a1*c1 + a2*c2 + a3*c3)) / (a1*e1 - a1*c1 + a2*e2 - a2*c2 + a3*e3 - a3*c3)
     
     The PerceivedBrightness() function is a dot product between the a vector and its input, so the
     previous equation is equivalent to:
     p = (t - PerceivedBrightness(c1, c2, c3) / PerceivedBrightness(e1-c1, e2-c2, e3-c3)
     */
    const CGFloat c1 = r;
    const CGFloat c2 = g;
    const CGFloat c3 = b;
    
    CGFloat k;
    if (PerceivedBrightness(r, g, b) < t) {
        k = 1;
    } else {
        k = 0;
    }
    const CGFloat e1 = k;
    const CGFloat e2 = k;
    const CGFloat e3 = k;
    
    CGFloat p = ((t - PerceivedBrightness(c1, c2, c3)) /
                 (PerceivedBrightness(e1 - c1, e2 - c2, e3 - c3)));
    // p can be out of range for e.g., division by 0.
    p = MIN(1, MAX(0, p));

    result[0] = p * e1 + (1 - p) * c1;
    result[1] = p * e2 + (1 - p) * c2;
    result[2] = p * e3 + (1 - p) * c3;
    result[3] = a;
}

+ (instancetype)colorForAnsi256ColorIndex:(int)index {
    double r, g, b;
    if (index >= 16 && index < 232) {
        int i = index - 16;
        r = (i / 36) ? ((i / 36) * 40 + 55) / 255.0 : 0.0;
        g = (i % 36) / 6 ? (((i % 36) / 6) * 40 + 55) / 255.0 : 0.0;
        b = (i % 6) ? ((i % 6) * 40 + 55) / 255.0 : 0.0;
    } else if (index >= 232 && index < 256) {
        int i = index - 232;
        r = g = b = (i * 10 + 8) / 255.0;
    } else {
        // The first 16 colors aren't supported here.
        return nil;
    }
    return [UIColor colorWithRed:r
                           green:g
                            blue:b
                           alpha:1];
}

+ (void)getComponents:(CGFloat *)result
        forComponents:(CGFloat *)mainComponents
  withContrastAgainstComponents:(CGFloat *)otherComponents
                minimumContrast:(CGFloat)minimumContrast {
    const double r = mainComponents[0];
    const double g = mainComponents[1];
    const double b = mainComponents[2];
    const double a = mainComponents[3];

    const double or = otherComponents[0];
    const double og = otherComponents[1];
    const double ob = otherComponents[2];

    double mainBrightness = PerceivedBrightness(r, g, b);
    double otherBrightness = PerceivedBrightness(or, og, ob);
    CGFloat brightnessDiff = fabs(mainBrightness - otherBrightness);

    if (brightnessDiff < minimumContrast) {
        CGFloat error = fabs(brightnessDiff - minimumContrast);
        CGFloat targetBrightness = mainBrightness;
        if (mainBrightness < otherBrightness) {
            // To increase contrast, return a color that's dimmer than mainComponents
            targetBrightness -= error;
            if (targetBrightness < 0) {
                const double alternative = otherBrightness + minimumContrast;
                const double baseContrast = otherBrightness;
                const double altContrast = MIN(alternative, 1) - otherBrightness;
                if (altContrast > baseContrast) {
                    targetBrightness = alternative;
                }
            }
        } else {
            // To increase contrast, return a color that's brighter than mainComponents
            targetBrightness += error;
            if (targetBrightness > 1) {
                const double alternative = otherBrightness - minimumContrast;
                const double baseContrast = 1 - otherBrightness;
                const double altContrast = otherBrightness - MAX(alternative, 0);
                if (altContrast > baseContrast) {
                    targetBrightness = alternative;
                }
            }
        }
        targetBrightness = MIN(MAX(0, targetBrightness), 1);

        [self getComponents:result
            forColorWithRed:r
                      green:g
                       blue:b
                      alpha:a
        perceivedBrightness:targetBrightness];
    } else {
        memmove(result, mainComponents, sizeof(CGFloat) * 4);
    }
}

- (int)nearestIndexIntoAnsi256ColorTable {
    CGFloat rc, gc, bc;
    [self getRed:&rc green:&gc blue:&bc alpha:nil];

    int r = 5 * rc;
    int g = 5 * gc;
    int b = 5 * bc;
    return 16 + b + g * 6 + r * 36;
}

- (instancetype)colorDimmedBy:(double)dimmingAmount towardsGrayLevel:(double)grayLevel {
    if (dimmingAmount == 0) {
        return self;
    }
    CGFloat r, g, b, alpha;
    [self getRed:&r green:&g blue:&b alpha:&alpha];
    // This algorithm limits the dynamic range of colors as well as brightening
    // them. Both attributes change in proportion to the dimmingAmount.
    
    // Find a linear interpolation between kCenter and the requested color component
    // in proportion to 1- dimmingAmount.
    return [UIColor colorWithRed:(1 - dimmingAmount) * r + dimmingAmount * grayLevel
                           green:(1 - dimmingAmount) * g + dimmingAmount * grayLevel
                            blue:(1 - dimmingAmount) * b + dimmingAmount * grayLevel
                           alpha:alpha];
}

- (CGFloat)perceivedBrightness {
    CGFloat r, g, b;
    [self getRed:&r green:&g blue:&b alpha:nil];
    return PerceivedBrightness(r, g, b);
}

- (BOOL)isDark {
    return [self perceivedBrightness] < 0.5;
}

- (NSDictionary *)dictionaryValue {
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return @{ kEncodedColorDictionaryColorSpace: kEncodedColorDictionarySRGBColorSpace,
              kEncodedColorDictionaryRedComponent: @(red),
              kEncodedColorDictionaryGreenComponent: @(green),
              kEncodedColorDictionaryBlueComponent: @(blue),
              kEncodedColorDictionaryAlphaComponent: @(alpha) };
}

- (instancetype)colorByPremultiplyingAlphaWithColor:(UIColor *)background {
    CGFloat fr, fg, fb, fa;
    [self getRed:&fr green:&fg blue:&fb alpha:&fa];
    CGFloat br, bg, bb, ba;
    [background getRed:&br green:&bg blue:&bb alpha:&ba];
    CGFloat a[4] = { fr, fg, fb, fa };
    CGFloat b[4] = { br, bg, bb, ba };
    CGFloat x[4];
    for (int i = 0; i < 3; i++) {
        x[i] = a[i] * fa + b[i] * (1 - fa);
    }
    return [UIColor colorWithRed:x[0] green:x[1] blue:x[2] alpha:ba];
}

- (NSString *)hexString {
    NSDictionary *dict = [self dictionaryValue];
    int red = [dict[kEncodedColorDictionaryRedComponent] doubleValue] * 255;
    int green = [dict[kEncodedColorDictionaryGreenComponent] doubleValue] * 255;
    int blue = [dict[kEncodedColorDictionaryBlueComponent] doubleValue] * 255;
    return [NSString stringWithFormat:@"#%02x%02x%02x", red, green, blue];
}

+ (instancetype)colorFromHexString:(NSString *)hexString {
    if (![hexString hasPrefix:@"#"] || hexString.length != 7) {
        return nil;
    }

    NSScanner *scanner = [NSScanner scannerWithString:[hexString substringFromIndex:1]];
    unsigned long long ll;
    if (![scanner scanHexLongLong:&ll]) {
        return nil;
    }
    CGFloat red = (ll >> 16) & 0xff;
    CGFloat green = (ll >> 8) & 0xff;
    CGFloat blue = (ll >> 0) & 0xff;
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
}

@end
