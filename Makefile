APP_NAME := Pasteboard Reset
EXECUTABLE_NAME := $(APP_NAME)
PRODUCT_BUNDLE_IDENTIFIER := org.gridstats.Pasteboard-Reset
MACOSX_DEPLOYMENT_TARGET := 10.9
CONFIGURATION ?= Release

BUILD_DIR := build/$(CONFIGURATION)
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
ICON_STAMP := $(BUILD_DIR)/.icon.stamp
RESOURCES_STAMP := $(BUILD_DIR)/.resources.stamp
SIGN_STAMP := $(BUILD_DIR)/.sign.stamp

SOURCES := Sources/main.m Sources/AppDelegate.m
INFO_PLIST := Sources/Info.plist

SDKROOT := $(shell xcrun --sdk macosx --show-sdk-path)
CLANG := xcrun clang
CODESIGN := codesign
PLUTIL := plutil
PYTHON := python3

COMMON_CFLAGS := \
	-fobjc-arc \
	-fmodules \
	-fobjc-abi-version=2 \
	-fobjc-legacy-dispatch \
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

.PHONY: all debug release prepare-build run sign clean icon pngcrush

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
		rm -f "$(BINARY_STAMP)" "$(PLIST_STAMP)" "$(ICON_STAMP)" "$(RESOURCES_STAMP)" "$(SIGN_STAMP)"; \
	fi

$(BINARY_STAMP): $(SOURCES) Sources/AppDelegate.h Sources/Prefix.pch
	@mkdir -p "$(MACOS_DIR)"
	$(CLANG) $(COMMON_CFLAGS) $(CONFIGURATION_CFLAGS) \
		-framework Cocoa \
		-o "$(EXECUTABLE)" \
		$(SOURCES)
	@touch "$@"

$(PLIST_STAMP): $(INFO_PLIST)
	@mkdir -p "$(CONTENTS_DIR)"
	cp "$(INFO_PLIST)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleExecutable -string "$(EXECUTABLE_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleName -string "$(APP_NAME)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace CFBundleIdentifier -string "$(PRODUCT_BUNDLE_IDENTIFIER)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -replace LSMinimumSystemVersion -string "$(MACOSX_DEPLOYMENT_TARGET)" "$(PROCESSED_INFO_PLIST)"
	$(PLUTIL) -lint "$(PROCESSED_INFO_PLIST)"
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

$(SIGN_STAMP): $(BINARY_STAMP) $(PLIST_STAMP) $(ICON_STAMP) $(RESOURCES_STAMP)
	$(CODESIGN) --force --deep --sign - "$(APP_DIR)"
	@touch "$@"

run: release
	open "$(APP_DIR)"

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
