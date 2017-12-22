//
//  iTermImageInfo.m
//  iTerm2
//
//  Created by George Nachman on 5/11/15.
//
//

@import MobileCoreServices;

#import "iTermImageInfo.h"

#import "DebugLogging.h"
#import "iTermAnimatedImageInfo.h"
#import "iTermImage.h"
#import "NSData+iTerm.h"
#import "UIImage+iTerm.h"

static NSString *const kImageInfoSizeKey = @"Size";
static NSString *const kImageInfoImageKey = @"Image";  // data
static NSString *const kImageInfoPreserveAspectRatioKey = @"Preserve Aspect Ratio";
static NSString *const kImageInfoFilenameKey = @"Filename";
static NSString *const kImageInfoInsetKey = @"Edge Insets";
static NSString *const kImageInfoCodeKey = @"Code";
static NSString *const kImageInfoBrokenKey = @"Broken";

NSString *const iTermImageDidLoad = @"iTermImageDidLoad";

@interface iTermImageInfo ()

@property(nonatomic, retain) NSMutableDictionary *embeddedImages;  // frame number->downscaled image
@property(nonatomic, assign) unichar code;
@property(nonatomic, retain) iTermAnimatedImageInfo *animatedImage;  // If animated GIF, this is nonnil
@end

@implementation iTermImageInfo {
    NSData *_data;
    NSString *_uniqueIdentifier;
    NSDictionary *_dictionary;
    void (^_queuedBlock)(void);
}

- (instancetype)initWithCode:(unichar)code {
    self = [super init];
    if (self) {
        _code = code;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _size = [dictionary[kImageInfoSizeKey] CGSizeValue];
        _broken = [dictionary[kImageInfoBrokenKey] boolValue];
        _inset = [dictionary[kImageInfoInsetKey] UIEdgeInsetsValue];
        _data = [dictionary[kImageInfoImageKey] retain];
        _dictionary = [dictionary copy];
        _preserveAspectRatio = [dictionary[kImageInfoPreserveAspectRatioKey] boolValue];
        _filename = [dictionary[kImageInfoFilenameKey] copy];
        _code = [dictionary[kImageInfoCodeKey] shortValue];
    }
    return self;
}

- (NSString *)uniqueIdentifier {
    if (!_uniqueIdentifier) {
        _uniqueIdentifier = [[[NSUUID UUID] UUIDString] copy];
    }
    return _uniqueIdentifier;
}

- (void)loadFromDictionaryIfNeeded {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    static NSMutableArray *blocks;
    dispatch_once(&onceToken, ^{
        blocks = [[NSMutableArray alloc] init];
        queue = dispatch_queue_create("com.iterm2.LazyImageDecoding", DISPATCH_QUEUE_SERIAL);
    });

    if (!_dictionary) {
        @synchronized (self) {
            if (_queuedBlock) {
                // Move to the head of the queue.
                NSUInteger index = [blocks indexOfObjectIdenticalTo:_queuedBlock];
                if (index != NSNotFound) {
                    [blocks removeObjectAtIndex:index];
                    [blocks insertObject:_queuedBlock atIndex:0];
                }
            }
        }
        return;
    }
    
    [_dictionary release];
    _dictionary = nil;
    
    DLog(@"Queueing load of %@", self.uniqueIdentifier);
    void (^block)(void) = ^{
        // This is a slow operation that blocks for a long time.
        iTermImage *image = [iTermImage imageWithCompressedData:_data];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_queuedBlock release];
            _queuedBlock = nil;
            _animatedImage = [[iTermAnimatedImageInfo alloc] initWithImage:image];
            if (!_animatedImage) {
                _image = [image retain];
            }
            DLog(@"Loaded %@", self.uniqueIdentifier);
            [[NSNotificationCenter defaultCenter] postNotificationName:iTermImageDidLoad object:self];
        });
    };
    _queuedBlock = [block copy];
    @synchronized(self) {
        [blocks insertObject:_queuedBlock atIndex:0];
    }
    dispatch_async(queue, ^{
        void (^blockToRun)(void) = nil;
        @synchronized(self) {
            blockToRun = [blocks firstObject];
            [blockToRun retain];
            [blocks removeObjectAtIndex:0];
        }
        blockToRun();
        [blockToRun release];
    });
}

- (void)dealloc {
    [_filename release];
    [_image release];
    [_embeddedImages release];
    [_animatedImage release];
    [_data release];
    [_dictionary release];
    [_uniqueIdentifier release];
    [super dealloc];
}

- (void)saveToFile:(NSString *)filename {
  UIImage *image = self.image.images.firstObject;
  if ([filename hasSuffix:@".jpg"] || [filename hasSuffix:@".jpeg"]) {
    [UIImageJPEGRepresentation(image, 0.9f) writeToFile:filename atomically:NO];
  } else {
    // just fall back to PNG for anything else
    [UIImagePNGRepresentation(image) writeToFile:filename atomically:NO];
  }
}

- (void)setImageFromImage:(iTermImage *)image data:(NSData *)data {
    [_dictionary release];
    _dictionary = nil;

    [_animatedImage autorelease];
    _animatedImage = [[iTermAnimatedImageInfo alloc] initWithImage:image];

    [_data autorelease];
    _data = [data retain];

    [_image autorelease];
    _image = [image retain];
}

- (NSString *)imageType {
    NSString *type = [_data uniformTypeIdentifierForImageData];
    if (type) {
        return type;
    }

    return (NSString *)kUTTypeImage;
}

- (NSDictionary *)dictionary {
    return @{ kImageInfoSizeKey: [NSValue valueWithCGSize:_size],
              kImageInfoInsetKey: [NSValue valueWithUIEdgeInsets:_inset],
              kImageInfoImageKey: _data ?: [NSData data],
              kImageInfoPreserveAspectRatioKey: @(_preserveAspectRatio),
              kImageInfoFilenameKey: _filename ?: @"",
              kImageInfoCodeKey: @(_code),
              kImageInfoBrokenKey: @(_broken) };
}


- (BOOL)animated {
    return !_paused && _animatedImage != nil;
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    _animatedImage.paused = paused;
}

- (iTermImage *)image {
    [self loadFromDictionaryIfNeeded];
    return _image;
}

- (iTermAnimatedImageInfo *)animatedImage {
    [self loadFromDictionaryIfNeeded];
    return _animatedImage;
}

- (UIImage *)imageWithCellSize:(CGSize)cellSize {
    if (!self.image && !self.animatedImage) {
        return nil;
    }
    if (!_embeddedImages) {
        _embeddedImages = [[NSMutableDictionary alloc] init];
    }
    int frame = self.animatedImage.currentFrame;  // 0 if not animated
    UIImage *embeddedImage = _embeddedImages[@(frame)];

    CGSize region = CGSizeMake(cellSize.width * _size.width,
                               cellSize.height * _size.height);
    if (!CGSizeEqualToSize(embeddedImage.size, region)) {
        UIGraphicsBeginImageContextWithOptions(region, NO, 1);
        CGSize size;
        UIImage *theImage;
        if (self.animatedImage) {
            theImage = [self.animatedImage imageForFrame:frame];
        } else {
            theImage = [self.image.images firstObject];
        }
        if (!_preserveAspectRatio) {
            size = region;
        } else {
            double imageAR = theImage.size.width / theImage.size.height;
            double canvasAR = region.width / region.height;
            if (imageAR > canvasAR) {
                // image is wider than canvas, add black bars on top and bottom
                size = CGSizeMake(region.width, region.width / imageAR);
            } else {
                // image is taller than canvas, add black bars on sides
                size = CGSizeMake(region.height * imageAR, region.height);
            }
        }
        UIEdgeInsets inset = _inset;
        inset.top *= cellSize.height;
        inset.bottom *= cellSize.height;
        inset.left *= cellSize.width;
        inset.right *= cellSize.width;
        [theImage drawInRect:CGRectMake((region.width - size.width) / 2 + inset.left,
                                        (region.height - size.height) / 2 + inset.bottom,
                                        MAX(0, size.width - inset.left - inset.right),
                                        MAX(0, size.height - inset.top - inset.bottom))];
        
        UIImage *canvas = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        self.embeddedImages[@(frame)] = canvas;
    }
    return _embeddedImages[@(frame)];
}

- (NSString *)nameForNewSavedTempFile {
    NSString *format = [NSTemporaryDirectory() stringByAppendingPathComponent:@"iTerm2.XXXXXX"];
    char *tempName = mktemp((char *)format.UTF8String);
    NSString *name = [[[NSString alloc] initWithBytesNoCopy:tempName length:strlen(tempName) encoding:NSUTF8StringEncoding freeWhenDone:YES] autorelease];

    [self.data writeToFile:name atomically:NO];
    return name;
}

@end
