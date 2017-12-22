//
//  iTermImage.m
//  iTerm2
//
//  Created by George Nachman on 8/27/16.
//
//

@import ImageIO;

#import "iTermImage.h"
#import "DebugLogging.h"
#import "iTermImageDecoderDriver.h"
#import "NSData+iTerm.h"
#import "UIImage+iTerm.h"

static const CGFloat kMaxDimension = 10000;

@interface iTermImage()
@property(nonatomic, retain) NSMutableArray<NSNumber *> *delays;
@property(nonatomic, readwrite) NSSize size;
@property(nonatomic, retain) NSMutableArray<UIImage *> *images;
@end

#if 0
static NSDictionary *GIFProperties(CGImageSourceRef source, size_t i) {
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        NSDictionary *gifProperties = (NSDictionary *)CFDictionaryGetValue(properties,
                                                                           kCGImagePropertyGIFDictionary);
        gifProperties = [[gifProperties copy] autorelease];
        CFRelease(properties);
        return gifProperties;
    } else {
        return nil;
    }
}

static NSTimeInterval DelayInGifProperties(NSDictionary *gifProperties) {
    NSTimeInterval delay = 0.01;
    if (gifProperties) {
        NSNumber *number = (id)CFDictionaryGetValue((CFDictionaryRef)gifProperties,
                                                    kCGImagePropertyGIFUnclampedDelayTime);
        if (number == NULL || [number doubleValue] == 0) {
            number = (id)CFDictionaryGetValue((CFDictionaryRef)gifProperties,
                                              kCGImagePropertyGIFDelayTime);
        }
        if ([number doubleValue] > 0) {
            delay = number.doubleValue;
        }
    }

    return delay;
}
#endif

@implementation iTermImage

+ (instancetype)imageWithNativeImage:(UIImage *)nativeImage {
    iTermImage *image = [[iTermImage alloc] init];
    image.size = nativeImage.size;
    [image.images addObject:nativeImage];
    return image;
}

+ (instancetype)imageWithCompressedData:(NSData *)compressedData {
    // TODO(kirb): meh?
// #if DEBUG
    NSLog(@"** WARNING: Decompressing image in-process **");
    return [[iTermImage alloc] initWithData:compressedData];
/*
#else
    iTermImageDecoderDriver *driver = [[[iTermImageDecoderDriver alloc] init] autorelease];
    NSData *jsonData = [driver jsonForCompressedImageData:compressedData];
    if (jsonData) {
        return [[[iTermImage alloc] initWithJson:jsonData] autorelease];
    } else {
        return nil;
    }
#endif
*/
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delays = [[NSMutableArray alloc] init];
        _images = [[NSMutableArray alloc] init];
    }
    return self;
}

// #if DEBUG
- (instancetype)initWithData:(NSData *)data {
    self = [self init];
    if (self) {
        UIImage *image = [[[UIImage alloc] initWithData:data] autorelease];
        // CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data,
                                                              // (CFDictionaryRef)@{});
        _size = image.size;

        // TODO(kirb): implement gifs?
    }
    return self;
}
// #endif

- (instancetype)initWithJson:(NSData *)json {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    if (!dict) {
        DLog(@"nil json");
        return nil;
    }
    if (![dict isKindOfClass:[NSDictionary class]]) {
        DLog(@"json root of class %@", [dict class]);
        return nil;
    }
    
    self = [self init];
    if (self) {
        NSArray *delays = dict[@"delays"];
        if (![delays isKindOfClass:[NSArray class]]) {
            DLog(@"delays of class %@", [delays class]);
            return nil;
        }
        
        NSArray *size = dict[@"size"];
        if (![size isKindOfClass:[NSArray class]]) {
            DLog(@"size of class %@", [size class]);
            return nil;
        }
        if (size.count != 2) {
            DLog(@"size has %@ elements", @(size.count));
            return nil;
        }

        NSArray *imageData = dict[@"images"];
        if (![imageData isKindOfClass:[NSArray class]]) {
            DLog(@"imageData of class %@", [imageData class]);
            return nil;
        }
        
        if (delays.count != 0 && delays.count != imageData.count) {
            DLog(@"delays.count=%@, imageData.count=%@", @(delays.count), @(imageData.count));
            return nil;
        }
        
        _size = CGSizeMake([size[0] doubleValue], [size[1] doubleValue]);
        if (_size.width <= 0 || _size.width >= kMaxDimension ||
            _size.height <= 0 || _size.height >= kMaxDimension) {
            DLog(@"Bogus size %@", NSStringFromCGSize(_size));
            return nil;
        }
        
        for (id delay in delays) {
            if (![delay isKindOfClass:[NSNumber class]]) {
                DLog(@"Bogus delay of class %@", [delay class]);
                return nil;
            }
            [_delays addObject:delay];
        }
        
        for (NSString *imageString in imageData) {
            if (![imageString isKindOfClass:[NSString class]]) {
                DLog(@"Bogus image string of class %@", [imageString class]);
            }

            NSData *data = [NSData dataWithBase64EncodedString:imageString];
            if (!data || data.length > kMaxDimension * kMaxDimension * 4) {
                DLog(@"Could not decode base64 encoded image string");
                return nil;
            }
            
            if (data.length < _size.width * _size.height * 4) {
                DLog(@"data too small %@ < %@", @(data.length), @(_size.width * _size.height * 4));
                return nil;
            }
            
            UIImage *image = [UIImage imageWithData:data];
            if (!image) {
                DLog(@"Failed to create UIImage from data");
                return nil;
            }
            [_images addObject:image];
        }
    }

    return self;
}

- (void)dealloc {
    [_images release];
    [_delays release];
    [super dealloc];
}

@end
