//
//  iTermImage.h
//  iTerm2
//
//  Created by George Nachman on 8/27/16.
//
//

@interface iTermImage : NSObject

// For animated gifs, delays is 1:1 with images. For non-animated images, delays is empty.
@property(nonatomic, readonly) NSMutableArray<NSNumber *> *delays;
@property(nonatomic, readonly) CGSize size;
@property(nonatomic, readonly) NSMutableArray<UIImage *> *images;

// Animated GIFs are not supported through this interface.
+ (instancetype)imageWithNativeImage:(UIImage *)image;

// Decompresses in a sandboxed process. Returns nil if anything goes wrong.
+ (instancetype)imageWithCompressedData:(NSData *)data;

@end
