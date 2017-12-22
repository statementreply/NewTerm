//
//  NSImage+iTerm.m
//  iTerm
//
//  Created by George Nachman on 7/20/14.
//
//

@import MobileCoreServices;

#import "UIColor+iTerm.h"
#import "UIImage+iTerm.h"

@implementation UIImage (iTerm)

+ (NSString *)extensionForUniformType:(NSString *)type {
    NSDictionary *map = @{ (NSString *)kUTTypeBMP: @"bmp",
                           (NSString *)kUTTypeGIF: @"gif",
                           (NSString *)kUTTypeJPEG2000: @"jp2",
                           (NSString *)kUTTypeJPEG: @"jpeg",
                           (NSString *)kUTTypePNG: @"png",
                           (NSString *)kUTTypeTIFF: @"tiff",
                           (NSString *)kUTTypeICO: @"ico" };
    return map[type];
}

- (CGContextRef)newBitmapContextWithStorage:(NSMutableData *)data {
  NSSize size = self.size;
  NSInteger bytesPerRow = size.width * 4;
  NSUInteger storageNeeded = bytesPerRow * size.height;
  [data setLength:storageNeeded];

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate((void *)data.bytes,
                                               size.width,
                                               size.height,
                                               8,
                                               bytesPerRow,
                                               colorSpace,
                                               (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);
  if (!context) {
    return NULL;
  }

  return context;
}

- (UIImage *)imageWithColor:(UIColor *)color {
  NSSize size = self.size;
  CGRect rect = CGRectZero;
  rect.size = size;

  // Create a bitmap context.
  NSMutableData *data = [NSMutableData data];
  CGContextRef context = [self newBitmapContextWithStorage:data];

  // Draw myself into that context.
  CGContextDrawImage(context, rect, [self CGImage]);

  // Now draw over it with |color|.
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
  CGContextFillRect(context, rect);

  // Extract the resulting image into the graphics context.
  CGImageRef image = CGBitmapContextCreateImage(context);

  // Convert to UIImage
  UIImage *coloredImage = [[[UIImage alloc] initWithCGImage:image] autorelease];

  // Release memory.
  CGContextRelease(context);
  CGImageRelease(image);

  return coloredImage;
}

@end
