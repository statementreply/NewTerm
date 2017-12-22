#import "ScreenChar.h"

typedef NS_ENUM(NSInteger, ITermCursorType) {
    CURSOR_UNDERLINE,
    CURSOR_VERTICAL,
    CURSOR_BOX,

    CURSOR_DEFAULT = -1  // Use the default cursor type for a profile. Internally used for DECSTR.
};

typedef struct {
    screen_char_t chars[3][3];
    BOOL valid[3][3];
} iTermCursorNeighbors;

@protocol iTermCursorDelegate <NSObject>

- (iTermCursorNeighbors)cursorNeighbors;

- (void)cursorDrawCharacterAt:(VT100GridCoord)coord
                  doubleWidth:(BOOL)doubleWidth
                overrideColor:(UIColor*)overrideColor
                      context:(CGContextRef)ctx
              backgroundColor:(UIColor *)backgroundColor;

- (UIColor *)cursorColorForCharacter:(screen_char_t)screenChar
                      wantBackground:(BOOL)wantBackgroundColor
                               muted:(BOOL)muted;

- (UIColor *)cursorWhiteColor;
- (UIColor *)cursorBlackColor;
- (UIColor *)cursorColorByDimmingSmartColor:(UIColor *)color;

@end

@interface iTermCursor : NSObject

@property(nonatomic, assign) id<iTermCursorDelegate> delegate;

+ (iTermCursor *)cursorOfType:(ITermCursorType)theType;
+ (instancetype)copyModeCursorInSelectionState:(BOOL)selecting;

// No default implementation.
- (void)drawWithRect:(CGRect)rect
         doubleWidth:(BOOL)doubleWidth
          screenChar:(screen_char_t)screenChar
     backgroundColor:(UIColor *)backgroundColor
     foregroundColor:(UIColor *)foregroundColor
               smart:(BOOL)smart
             focused:(BOOL)focused
               coord:(VT100GridCoord)coord
             outline:(BOOL)outline;


@end
