APP_NAME := Pasteboard Reset
EXECUTABLE_NAME := $(APP_NAME)
PRODUCT_BUNDLE_IDENTIFIER := org.gridstats.Pasteboard-Reset
MACOSX_DEPLOYMENT_TARGET := 11.0
CONFIGURATION ?= Release
SIGN_IDENTITY ?= -
NOTARY_PROFILE ?=
VERSION_FILE := VERSION
VERSION ?= $(shell sed -n '1p' "$(VERSION_FILE)")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD 2>/dev/null || printf '1')
TAG_PREFIX ?= v

BUILD_DIR := build/$(CONFIGURATION)
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
BINARY_STAMP := $(BUILD_DIR)/.binary.stamp
PLIST_STAMP := $(BUILD_DIR)/.plist.stamp
PLIST_VERSION_STAMP := $(BUILD_DIR)/.plist.version
ICON_STAMP := $(BUILD_DIR)/.icon.stamp
RESOURCES_STAMP := $(BUILD_DIR)/.resources.stamp
SIGN_STAMP := $(BUILD_DIR)/.sign.stamp
SIGN_IDENTITY_STAMP := $(BUILD_DIR)/.sign.identity

SOURCES := Sources/main.m Sources/AppDelegate.m
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

ifeq ($(CONFIGURATION),Debug)
CONFIGURATION_CFLAGS := $(DEBUG_CFLAGS)
else
CONFIGURATION_CFLAGS := $(RELEASE_CFLAGS)
endif

.PHONY: all debug release prepare-build run sign archive notarize staple release-tag version clean icon pngcrush

all: release

debug:
	$(MAKE) CONFIGURATION=Debug prepare-build
	$(MAKE) CONFIGURATION=Debug build

release:
	$(MAKE) CONFIGURATION=Release prepare-build
	$(MAKE) CONFIGURATION=Release build

build: $(SIGN_STAMP)

prepare-build:
	@if [ ! -d "$(APP_DIR)" ] || \
		[ ! -x "$(EXECUTABLE)" ] || \
		[ ! -f "$(PROCESSED_INFO_PLIST)" ] || \
		[ ! -f "$(ICNS_FILE)" ] || \
		[ ! -f "$(RESOURCES_DIR)/pasteboard-reset.ttf" ] || \
		[ ! -f "$(RESOURCES_DIR)/en.lproj/Localizable.strings" ]; then \
		rm -f "$(BINARY_STAMP)" "$(PLIST_STAMP)" "$(ICON_STAMP)" "$(RESOURCES_STAMP)" "$(SIGN_STAMP)" "$(SIGN_IDENTITY_STAMP)"; \
	fi
	@if [ -f "$(SIGN_STAMP)" ] && { [ ! -f "$(SIGN_IDENTITY_STAMP)" ] || [ "$$(cat "$(SIGN_IDENTITY_STAMP)")" != "$(SIGN_IDENTITY)" ]; }; then \
		rm -f "$(SIGN_STAMP)"; \
	fi
	@if [ -f "$(PLIST_STAMP)" ] && { [ ! -f "$(PLIST_VERSION_STAMP)" ] || [ "$$(cat "$(PLIST_VERSION_STAMP)")" != "$(VERSION)|$(BUILD_NUMBER)" ]; }; then \
		rm -f "$(PLIST_STAMP)" "$(SIGN_STAMP)"; \
	fi

$(BINARY_STAMP): $(SOURCES) Sources/AppDelegate.h Sources/Prefix.pch
	@mkdir -p "$(MACOS_DIR)"
	$(CLANG) $(COMMON_CFLAGS) $(CONFIGURATION_CFLAGS) \
		-framework Cocoa \
		-o "$(EXECUTABLE)" \
		$(SOURCES)
	@touch "$@"

$(PLIST_STAMP): $(PLIST_DEPS)
	@mkdir -p "$(CONTENTS_DIR)"
	cp "$(INFO_PLIST)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleExecutable -string "$(EXECUTABLE_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleName -string "$(APP_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleIdentifier -string "$(PRODUCT_BUNDLE_IDENTIFIER)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleShortVersionString -string "$(VERSION)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleVersion -string "$(BUILD_NUMBER)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace LSMinimumSystemVersion -string "$(MACOSX_DEPLOYMENT_TARGET)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -lint "$(PROCESSED_INFO_PLIST)"
	@printf '%s|%s\n' "$(VERSION)" "$(BUILD_NUMBER)" > "$(PLIST_VERSION_STAMP)"
	@touch "$@"

$(ICON_STAMP): $(APPICONSET_DIR)/Contents.json
	@mkdir -p "$(RESOURCES_DIR)"
	$(PYTHON) bin/make_icns.py "$(APPICONSET_DIR)" "$(ICNS_FILE)"
	@touch "$@"

$(RESOURCES_STAMP): Resources/pasteboard-reset.ttf Resources/en.lproj/Localizable.strings
	@mkdir -p "$(RESOURCES_DIR)"
	cp "Resources/pasteboard-reset.ttf" "$(RESOURCES_DIR)/"
	@mkdir -p "$(RESOURCES_DIR)/en.lproj"
	cp "Resources/en.lproj/Localizable.strings" "$(RESOURCES_DIR)/en.lproj/"
	@touch "$@"

sign: $(SIGN_STAMP)

$(SIGN_STAMP): $(BINARY_STAMP) $(PLIST_STAMP) $(ICON_STAMP) $(RESOURCES_STAMP)
	$(CODESIGN) --force --options runtime --timestamp --sign "$(SIGN_IDENTITY)" "$(APP_DIR)"
	@printf '%s\n' "$(SIGN_IDENTITY)" > "$(SIGN_IDENTITY_STAMP)"
	@touch "$@"

archive: release
	@rm -f "$(ARCHIVE)"
	$(DITTO) -c -k --keepParent "$(APP_DIR)" "$(ARCHIVE)"

release-tag:
	@test -n "$(VERSION)" || (echo "VERSION is empty."; exit 1)
	@printf '%s\n' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' || (echo "VERSION must use semantic version format, such as 1.2.3."; exit 1)
	@test "$$(git status --porcelain)" = "" || (echo "Working tree must be clean before tagging."; exit 1)
	@test -z "$$(git tag --list "$(TAG_PREFIX)$(VERSION)")" || (echo "Tag $(TAG_PREFIX)$(VERSION) already exists."; exit 1)
	git tag -a "$(TAG_PREFIX)$(VERSION)" -m "Release $(VERSION)"
	@printf 'Created tag %s%s. Push it with: git push origin %s%s\n' "$(TAG_PREFIX)" "$(VERSION)" "$(TAG_PREFIX)" "$(VERSION)"

version:
	@printf '%s\n' "$(VERSION)"

notarize: archive
	@test -n "$(NOTARY_PROFILE)" || (echo "Set NOTARY_PROFILE to a notarytool keychain profile name."; exit 1)
	$(NOTARYTOOL) submit "$(ARCHIVE)" --keychain-profile "$(NOTARY_PROFILE)" --wait

staple: notarize
	xcrun stapler staple "$(APP_DIR)"

run: release
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
