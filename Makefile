# Paths
# App
APP_DIR = apps/dogear
FLUTTER_BUILD_DIR = $(APP_DIR)/build/windows/x64/runner/Release
# System
SYS_DIR = C:/Windows/System32

# Scripts
SCRIPTS_DIR = scripts
# Update icons
UPDATE_ICONS_SCRIPT = $(SCRIPTS_DIR)/Update-Icons.ps1
# Copy Runtime DLLs
COPY_RUNTIME_DLLs_SCRIPT = $(SCRIPTS_DIR)/Copy-Runtime-DLLs.ps1
# Package
PACKAGE_SCRIPT = $(SCRIPTS_DIR)/Setup.iss

build-flutter:
	@echo "Starting Flutter Build..."
	cd $(APP_DIR) && flutter build windows
	$(MAKE) copy-runtime
	@echo "Flutter Build Complete!"

copy-runtime:
	@echo "Injecting MSVC Runtimes into Release folder..."
	powershell -ExecutionPolicy Bypass -File $(COPY_RUNTIME_DLLs_SCRIPT) \
		-BuildDir $(FLUTTER_BUILD_DIR)

package:
	@echo "Packaging..."
	ISCC $(PACKAGE_SCRIPT)

update-icons:
	@echo "Updating Icons..."
	powershell -ExecutionPolicy Bypass -File $(UPDATE_ICONS_SCRIPT)

clean:
	cd $(APP_DIR) && flutter clean
