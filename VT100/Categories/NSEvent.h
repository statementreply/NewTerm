typedef NS_OPTIONS(NSUInteger, NSEventModifierFlags) {
	NSEventModifierFlagCapsLock = 1 << 16,
	NSEventModifierFlagShift = 1 << 17,
	NSEventModifierFlagControl = 1 << 18,
	NSEventModifierFlagOption = 1 << 19,
	NSEventModifierFlagCommand = 1 << 20,
	NSEventModifierFlagNumericPad = 1 << 21,
	NSEventModifierFlagHelp = 1 << 22,
	NSEventModifierFlagFunction = 1 << 23
};

#define NSAlphaShiftKeyMask NSEventModifierFlagCapsLock
#define NSShiftKeyMask NSEventModifierFlagShift
#define NSControlKeyMask NSEventModifierFlagControl
#define NSAlternateKeyMask NSEventModifierFlagOption
#define NSCommandKeyMask NSEventModifierFlagCommand
#define NSNumericPadKeyMask NSEventModifierFlagNumericPad
#define NSHelpKeyMask NSEventModifierFlagHelp
#define NSFunctionKeyMask NSEventModifierFlagFunction
