//
//  FutureMethods.h
//  iTerm
//
//  Created by George Nachman on 8/29/11.
//

@import UIKit;

@interface UIFont (Future)
// Does this font look bad without anti-aliasing? Relies on a private method.
- (BOOL)futureShouldAntialias;
@end
