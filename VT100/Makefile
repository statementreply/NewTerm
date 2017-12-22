include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = VT100
VT100_FILES = $(wildcard *.m) $(wildcard */*.m) $(wildcard ThirdParty/*/*.m)
VT100_FRAMEWORKS = CoreGraphics CoreText QuartzCore UIKit
VT100_CFLAGS = -I../headers -I. $(foreach dir,$(wildcard */) $(wildcard ThirdParty/*/),-I$(dir))
VT100_LIBRARIES = curses icucore
VT100_INSTALL_PATH = /Applications/NewTerm.app/Frameworks

include $(THEOS_MAKE_PATH)/framework.mk
