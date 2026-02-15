# Paths
# App
APP_DIR := apps/dogear
FLUTTER_BUILD_DIR = $(APP_DIR)/build/windows/x64/runner/Release
# System
SYS_DIR := C:/Windows/System32
# Distribution
DIST_DIR := dist

# Scripts
SCRIPTS_DIR := scripts
# Update icons
UPDATE_ICONS_SCRIPT = $(SCRIPTS_DIR)/Update-Icons.ps1
# Copy Runtime DLLs
COPY_RUNTIME_DLLs_SCRIPT = $(SCRIPTS_DIR)/Copy-Runtime-DLLs.ps1
# Package
PACKAGE_SCRIPT = $(SCRIPTS_DIR)/Setup.iss
GET_VERSION_SCRIPT = $(SCRIPTS_DIR)/Get-Version.ps1
APP_VER = $(shell powershell -NoProfile -ExecutionPolicy Bypass -File $(GET_VERSION_SCRIPT))
APP_NAME := DogEar
PLATFORM := Windows
ARCH := x64
SETUP_OUT_BASE_FILENAME = $(APP_NAME)_$(APP_VER)_$(PLATFORM)_$(ARCH)_Setup
# Generate Release Note
GEN_RELEASE_NOTE_SCRIPT = $(SCRIPTS_DIR)/Gen-Release-Note.ps1
RELEASE_NOTE_BASE_FILENAME = $(APP_NAME)_$(APP_VER)_Release_Note

# Publish
TAG_NAME = v$(APP_VER)
RELEASE_TITLE = "DogEar $(APP_VER)"
NOTES_FILE = $(DIST_DIR)/$(RELEASE_NOTE_BASE_FILENAME).md
EXE_FILE = $(DIST_DIR)/$(SETUP_OUT_BASE_FILENAME).exe

# Core Tasks. Execute these tasks in order: build -> package -> publish
# Cleans, Builds the Flutter app and copies the runtime DLLs.
build:
	@echo "Cleaning Previous Flutter Build..."
	$(MAKE) clean
	@echo "Starting Flutter Build..."
	cd $(APP_DIR) && flutter build windows
	$(MAKE) copy-runtime
	@echo "Flutter Build Complete!"

# Packages the app and generates release note.
package:
	@echo "Packaging $(SETUP_OUT_BASE_FILENAME).exe"
	ISCC /DMyAppVersion="$(APP_VER)" \
		/DOutputBaseFilename="$(SETUP_OUT_BASE_FILENAME)" \
		/O"$(DIST_DIR)" \
		$(PACKAGE_SCRIPT)
	$(MAKE) gen-release-note

build-package: build package

# Publishes the release to GitHub.
publish:
	@echo "Publishing to GitHub Release..."
	gh release create $(TAG_NAME) "$(EXE_FILE)" \
		--title $(RELEASE_TITLE) \
		--notes-file "$(NOTES_FILE)"

# Tools
# Updates icons
update-icons:
	@echo "Updating Icons..."
	powershell -ExecutionPolicy Bypass -File $(UPDATE_ICONS_SCRIPT)

# Prints the current version.
echo-version:
	@echo "$(APP_VER)"

# Cleans the Flutter app.
clean:
	cd $(APP_DIR) && flutter clean

# Tools that run automatically in the Core Tasks.
# This will run automatically in [package].
gen-release-note:
	@echo "Generating Release Note..."
	@powershell -ExecutionPolicy Bypass -File $(GEN_RELEASE_NOTE_SCRIPT) \
		-Version "$(APP_VER)" \
		-DistDir "$(DIST_DIR)" \
		-FileName "$(SETUP_OUT_BASE_FILENAME).exe" \
		-ReleaseNoteFilename "$(RELEASE_NOTE_BASE_FILENAME).md"

# This will run automatically in [build].
copy-runtime:
	@echo "Injecting MSVC Runtimes into Release folder..."
	powershell -ExecutionPolicy Bypass -File $(COPY_RUNTIME_DLLs_SCRIPT) \
		-BuildDir $(FLUTTER_BUILD_DIR)