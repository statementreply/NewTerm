//
//  FutureMethods.m
//  iTerm
//
//  Created by George Nachman on 8/29/11.
//  Copyright 2011 Georgetech. All rights reserved.
//

@import CoreText;
#import "FutureMethods.h"

static void *GetFunctionByName(NSString *library, char *func) {
    CFBundleRef bundle;
    CFURLRef bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef) library, kCFURLPOSIXPathStyle, true);
    CFStringRef functionName = CFStringCreateWithCString(kCFAllocatorDefault, func, kCFStringEncodingASCII);
    bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
    void *f = NULL;
    if (bundle) {
        f = CFBundleGetFunctionPointerForName(bundle, functionName);
        CFRelease(bundle);
    }
    CFRelease(functionName);
    CFRelease(bundleURL);
    return f;
}

@implementation UIFont(Future)

- (BOOL)futureShouldAntialias {
    typedef BOOL CTFontShouldAntialiasFunction(CTFontRef);
    static CTFontShouldAntialiasFunction *function = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        function = GetFunctionByName(@"/System/Library/Frameworks/CoreText.framework",
                                     "CTFontShouldAntiAlias");
    });
    if (function) {
        return function((CTFontRef)self);
    }
    return NO;
}

@end
