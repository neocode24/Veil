.PHONY: setup build debug run package release clean

APP_NAME := Veil
SCHEME := Veil
PROJECT := Veil/Veil.xcodeproj
BUILD_DIR := build
VERSION := 0.1.0
ZIP_NAME := $(APP_NAME)-$(VERSION).zip
SIGN_IDENTITY := Veil Debug Build

setup:
	brew install xcodegen
	cd Veil && xcodegen generate

build:
	cd Veil && xcodegen generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		ENABLE_HARDENED_RUNTIME=NO \
		build
	@APP_PATH="$$(find $(BUILD_DIR)/DerivedData -name '$(APP_NAME).app' -path '*/Release/*' | head -1)"; \
		codesign --force --sign "$(SIGN_IDENTITY)" --deep "$$APP_PATH" 2>/dev/null && \
		echo "Signed with: $(SIGN_IDENTITY)" || echo "Ad-hoc signed (sign identity not found)"

debug:
	cd Veil && xcodegen generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		ENABLE_HARDENED_RUNTIME=NO \
		build
	@APP_PATH="$$(find $(BUILD_DIR)/DerivedData -name '$(APP_NAME).app' -path '*/Debug/*' | head -1)"; \
		codesign --force --sign "$(SIGN_IDENTITY)" --deep "$$APP_PATH" 2>/dev/null && \
		echo "Signed with: $(SIGN_IDENTITY)" || echo "Ad-hoc signed (sign identity not found)"

run: build
	@APP_PATH="$$(find $(BUILD_DIR)/DerivedData -name '$(APP_NAME).app' -path '*/Release/*' | head -1)"; \
		if [ -z "$$APP_PATH" ]; then echo "Error: $(APP_NAME).app not found"; exit 1; fi; \
		pkill -f "$(APP_NAME).app" 2>/dev/null; sleep 1; \
		open "$$APP_PATH"; \
		echo "Running $$APP_PATH"

package: build
	@mkdir -p $(BUILD_DIR)/dist
	@rm -f $(BUILD_DIR)/dist/$(ZIP_NAME)
	@APP_PATH="$$(find $(BUILD_DIR)/DerivedData -name '$(APP_NAME).app' -path '*/Release/*' | head -1)"; \
		if [ -z "$$APP_PATH" ]; then \
			echo "Error: $(APP_NAME).app not found in build output"; \
			exit 1; \
		fi; \
		cp -R "$$APP_PATH" $(BUILD_DIR)/dist/$(APP_NAME).app; \
		cd $(BUILD_DIR)/dist && zip -r -q $(ZIP_NAME) $(APP_NAME).app; \
		echo "Packaged: $(BUILD_DIR)/dist/$(ZIP_NAME)"; \
		echo "SHA256: $$(shasum -a 256 $(ZIP_NAME) | cut -d' ' -f1)"

release: package
	@echo "Creating GitHub release v$(VERSION)..."
	gh release create v$(VERSION) \
		$(BUILD_DIR)/dist/$(ZIP_NAME) \
		--title "v$(VERSION)" \
		--notes "Release v$(VERSION)"
	@echo ""
	@echo "Update homebrew cask SHA256:"
	@echo "  $$(shasum -a 256 $(BUILD_DIR)/dist/$(ZIP_NAME) | cut -d' ' -f1)"

clean:
	rm -rf $(BUILD_DIR)
	rm -rf Veil/Veil.xcodeproj
