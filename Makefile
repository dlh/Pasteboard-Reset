APP_NAME := Pasteboard Reset
EXECUTABLE_NAME := $(APP_NAME)
PRODUCT_BUNDLE_IDENTIFIER := dev.dlh.pasteboard-reset
MACOSX_DEPLOYMENT_TARGET := 13.0
CONFIGURATION ?= release
SIGN_IDENTITY ?= -
NOTARY_PROFILE ?=
VERSION_FILE := VERSION
VERSION ?= $(shell sed -n '1p' "$(VERSION_FILE)")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD 2>/dev/null || printf '1')
TAG_PREFIX ?= v

BUILD_DIR := build
ARCHIVE_BASENAME := $(APP_NAME)-$(VERSION)
ARCHIVE := $(BUILD_DIR)/$(ARCHIVE_BASENAME).zip
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
EXECUTABLE := $(MACOS_DIR)/$(EXECUTABLE_NAME)
PROCESSED_INFO_PLIST := $(CONTENTS_DIR)/Info.plist
APPICONSET_DIR := Resources/Images.xcassets/AppIcon.appiconset
ICNS_FILE := $(RESOURCES_DIR)/AppIcon.icns
CLANG_MODULE_CACHE := $(BUILD_DIR)/ModuleCache
STAMP_BINARY := $(BUILD_DIR)/.binary.stamp
STAMP_PLIST := $(BUILD_DIR)/.plist.stamp
STAMP_ICON := $(BUILD_DIR)/.icon.stamp
STAMP_RESOURCES := $(BUILD_DIR)/.resources.stamp
STAMP_SIGN := $(BUILD_DIR)/.sign.stamp
PLIST_VERSION_FILE := $(BUILD_DIR)/.plist.version
PLIST_SETTINGS_FILE := $(BUILD_DIR)/.plist.settings
CONFIGURATION_FILE := $(BUILD_DIR)/.configuration
SIGN_IDENTITY_FILE := $(BUILD_DIR)/.sign.identity

SOURCES := Sources/main.m Sources/AppDelegate.m Sources/LaunchAtLoginController.m Sources/PreferencesController.m Sources/StatusItemButton.m Sources/StatusItemIcon.m
INFO_PLIST := Sources/Info.plist
PLIST_DEPS := $(INFO_PLIST) $(VERSION_FILE)

SDKROOT := $(shell xcrun --sdk macosx --show-sdk-path)
CLANG := xcrun clang
CODESIGN := codesign
DITTO := ditto
NOTARYTOOL := xcrun notarytool
PLUTIL := plutil
PYTHON := python3

COMMON_CFLAGS := \
	-fobjc-arc \
	-fmodules \
	-fmodules-cache-path=$(CLANG_MODULE_CACHE) \
	-include Sources/Prefix.pch \
	-isysroot $(SDKROOT) \
	-mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) \
	-Wall \
	-Wextra

DEBUG_CFLAGS := -O0 -g -DDEBUG=1
RELEASE_CFLAGS := -Os

ifeq ($(CONFIGURATION),debug)
CONFIGURATION_CFLAGS := $(DEBUG_CFLAGS)
else ifeq ($(CONFIGURATION),release)
CONFIGURATION_CFLAGS := $(RELEASE_CFLAGS)
else
$(error CONFIGURATION must be debug or release)
endif

.PHONY: all debug release build prepare-build run sign archive notarize staple semantic-release-prepare release-dry-run version clean icon pngcrush

all: release

debug:
	$(MAKE) CONFIGURATION=debug build

release:
	$(MAKE) CONFIGURATION=release build

build: prepare-build
	$(MAKE) CONFIGURATION="$(CONFIGURATION)" "$(STAMP_SIGN)"

prepare-build:
	@mkdir -p "$(BUILD_DIR)"
	@if [ -f "$(CONFIGURATION_FILE)" ] && [ "$$(cat "$(CONFIGURATION_FILE)")" != "$(CONFIGURATION)" ]; then \
		rm -f "$(STAMP_BINARY)" "$(STAMP_PLIST)" "$(STAMP_ICON)" "$(STAMP_RESOURCES)" "$(STAMP_SIGN)" "$(PLIST_VERSION_FILE)" "$(PLIST_SETTINGS_FILE)" "$(SIGN_IDENTITY_FILE)"; \
	fi
	@printf '%s\n' "$(CONFIGURATION)" > "$(CONFIGURATION_FILE)"
	@if [ ! -d "$(APP_DIR)" ] || \
		[ ! -x "$(EXECUTABLE)" ] || \
		[ ! -f "$(PROCESSED_INFO_PLIST)" ] || \
		[ ! -f "$(ICNS_FILE)" ] || \
		[ ! -f "$(RESOURCES_DIR)/pasteboard-reset.ttf" ] || \
		[ ! -f "$(RESOURCES_DIR)/en.lproj/Localizable.strings" ]; then \
		rm -f "$(STAMP_BINARY)" "$(STAMP_PLIST)" "$(STAMP_ICON)" "$(STAMP_RESOURCES)" "$(STAMP_SIGN)" "$(PLIST_SETTINGS_FILE)" "$(SIGN_IDENTITY_FILE)"; \
	fi
	@if [ -f "$(STAMP_SIGN)" ] && { [ ! -f "$(SIGN_IDENTITY_FILE)" ] || [ "$$(cat "$(SIGN_IDENTITY_FILE)")" != "$(SIGN_IDENTITY)" ]; }; then \
		rm -f "$(STAMP_SIGN)"; \
	fi
	@if [ -f "$(STAMP_PLIST)" ] && { [ ! -f "$(PLIST_VERSION_FILE)" ] || [ "$$(cat "$(PLIST_VERSION_FILE)")" != "$(VERSION)|$(BUILD_NUMBER)" ]; }; then \
		rm -f "$(STAMP_PLIST)" "$(STAMP_SIGN)"; \
	fi
	@if [ -f "$(STAMP_PLIST)" ] && { [ ! -f "$(PLIST_SETTINGS_FILE)" ] || [ "$$(cat "$(PLIST_SETTINGS_FILE)")" != "$(EXECUTABLE_NAME)|$(APP_NAME)|$(PRODUCT_BUNDLE_IDENTIFIER)|$(MACOSX_DEPLOYMENT_TARGET)" ]; }; then \
		rm -f "$(STAMP_PLIST)" "$(STAMP_SIGN)"; \
	fi

$(STAMP_BINARY): $(SOURCES) Sources/AppDelegate.h Sources/LaunchAtLoginController.h Sources/PreferencesController.h Sources/StatusItemButton.h Sources/StatusItemIcon.h Sources/Prefix.pch
	@mkdir -p "$(MACOS_DIR)"
	$(CLANG) $(COMMON_CFLAGS) $(CONFIGURATION_CFLAGS) \
		-framework Cocoa \
		-framework QuartzCore \
		-framework ServiceManagement \
		-o "$(EXECUTABLE)" \
		$(SOURCES)
	@touch "$@"

$(STAMP_PLIST): $(PLIST_DEPS)
	@mkdir -p "$(CONTENTS_DIR)"
	cp "$(INFO_PLIST)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleExecutable -string "$(EXECUTABLE_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleName -string "$(APP_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleIdentifier -string "$(PRODUCT_BUNDLE_IDENTIFIER)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleShortVersionString -string "$(VERSION)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleVersion -string "$(BUILD_NUMBER)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace LSMinimumSystemVersion -string "$(MACOSX_DEPLOYMENT_TARGET)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -lint "$(PROCESSED_INFO_PLIST)"
	@printf '%s|%s\n' "$(VERSION)" "$(BUILD_NUMBER)" > "$(PLIST_VERSION_FILE)"
	@printf '%s|%s|%s|%s\n' "$(EXECUTABLE_NAME)" "$(APP_NAME)" "$(PRODUCT_BUNDLE_IDENTIFIER)" "$(MACOSX_DEPLOYMENT_TARGET)" > "$(PLIST_SETTINGS_FILE)"
	@touch "$@"

$(STAMP_ICON): $(APPICONSET_DIR)/Contents.json
	@mkdir -p "$(RESOURCES_DIR)"
	$(PYTHON) bin/make_icns.py "$(APPICONSET_DIR)" "$(ICNS_FILE)"
	@touch "$@"

$(STAMP_RESOURCES): Resources/pasteboard-reset.ttf Resources/en.lproj/Localizable.strings
	@mkdir -p "$(RESOURCES_DIR)"
	cp "Resources/pasteboard-reset.ttf" "$(RESOURCES_DIR)/"
	@mkdir -p "$(RESOURCES_DIR)/en.lproj"
	cp "Resources/en.lproj/Localizable.strings" "$(RESOURCES_DIR)/en.lproj/"
	@touch "$@"

sign: build

$(STAMP_SIGN): $(STAMP_BINARY) $(STAMP_PLIST) $(STAMP_ICON) $(STAMP_RESOURCES)
	$(CODESIGN) --force --options runtime --timestamp --sign "$(SIGN_IDENTITY)" "$(APP_DIR)"
	@printf '%s\n' "$(SIGN_IDENTITY)" > "$(SIGN_IDENTITY_FILE)"
	@touch "$@"

archive: release
	@rm -f "$(ARCHIVE)"
	$(DITTO) -c -k --keepParent "$(APP_DIR)" "$(ARCHIVE)"

version:
	@printf '%s\n' "$(VERSION)"

release-dry-run:
	npm --prefix .release run release:dry-run

notarize: archive
	@test -n "$(NOTARY_PROFILE)" || (echo "Set NOTARY_PROFILE to a notarytool keychain profile name."; exit 1)
	$(NOTARYTOOL) submit "$(ARCHIVE)" --keychain-profile "$(NOTARY_PROFILE)" --wait

staple: notarize
	xcrun stapler staple "$(APP_DIR)"
	@rm -f "$(ARCHIVE)"
	$(DITTO) -c -k --keepParent "$(APP_DIR)" "$(ARCHIVE)"

semantic-release-prepare:
	@test -n "$(VERSION)" || (echo "VERSION is empty."; exit 1)
	@test -n "$(BUILD_NUMBER)" || (echo "BUILD_NUMBER is empty."; exit 1)
	@test -n "$(SIGN_IDENTITY)" || (echo "SIGN_IDENTITY is empty."; exit 1)
	@printf '%s\n' "$(VERSION)" > "$(VERSION_FILE)"
	$(MAKE) staple VERSION="$(VERSION)" BUILD_NUMBER="$(BUILD_NUMBER)" SIGN_IDENTITY="$(SIGN_IDENTITY)" NOTARY_PROFILE="$(NOTARY_PROFILE)"
	test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$(PROCESSED_INFO_PLIST)")" = "$(VERSION)"
	test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$(PROCESSED_INFO_PLIST)")" = "$(BUILD_NUMBER)"
	$(CODESIGN) --verify --deep --strict --verbose=4 "$(APP_DIR)"
	$(CODESIGN) -dv --verbose=4 "$(APP_DIR)" 2>&1 | grep -F "Authority=$(SIGN_IDENTITY)"
	xcrun stapler validate "$(APP_DIR)"
	spctl --assess --type execute --verbose=4 "$(APP_DIR)"

run:
	$(MAKE) CONFIGURATION="$(CONFIGURATION)" build
	"$(EXECUTABLE)"

clean:
	rm -rf build

icon:
	webkit2png --transparent \
		--fullsize \
		--dir=${TMPDIR} \
		--filename=icon \
		Resources/icon-template.html
	open ${TMPDIR}icon-full.png

pngcrush:
	@for f in $(shell find Resources -name '*.png'); do pngcrush -ow -l 9 $$f; done
