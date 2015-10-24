TARGET = iphone:clang:latest:7.0
GO_EASY_ON_ME = 1

# don't do this kids
_NO_MAKEDEP = 1

include $(THEOS)/makefiles/common.mk

GLOBAL_CFLAGS = -include NewTerm/NewTerm-Prefix.pch -Iheaders

FRAMEWORK_NAME = iTerm2
iTerm2_FILES = $(wildcard iTerm2/*.m) $(wildcard iTerm2/*.c) $(wildcard iTerm2/ThirdParty/*/*.m)
iTerm2_FRAMEWORKS = CoreGraphics MobileCoreServices QuartzCore UIKit
iTerm2_CFLAGS = $(GLOBAL_CFLAGS)
iTerm2_LIBRARIES = aprutil-1 curses
iTerm2_INSTALL_PATH = /Applications/NewTerm.app/Frameworks

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard NewTerm/*.m) $(wildcard NewTerm/SubProcess/*.m)
NewTerm_FRAMEWORKS = CoreGraphics iTerm2 UIKit
NewTerm_CFLAGS = $(GLOBAL_CFLAGS) -fobjc-arc -F$(THEOS_OBJ_DIR) -I$(THEOS_OBJ_DIR)
NewTerm_LDFLAGS = -F$(THEOS_OBJ_DIR) -I$(THEOS_OBJ_DIR) -L$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/application.mk

internal-iTerm2-all::
	$(ECHO_NOTHING)mkdir -p $(THEOS_OBJ_DIR)/iTerm2.framework/Headers$(ECHO_END)
	$(ECHO_NOTHING)rsync -ra $(wildcard iTerm2/*.h) $(THEOS_OBJ_DIR)/iTerm2.framework/Headers$(ECHO_END)

after-install::
	install.exec "killall NewTerm; sleep 0.2; sblaunch ws.hbang.Terminal" || true
