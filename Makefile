BUILD_DIR=build
APP=$(BUILD_DIR)/mac-arm64/r_view.app
BINARY=$(APP)/Contents/MacOS/r_view
ICNS=icon/r_view.icns

# Where "make install" puts things. Override for a machine-wide install:
#     make install PREFIX=/usr/local APPDIR=/Applications
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
APPDIR ?= $(HOME)/Applications
INSTALLED_APP=$(APPDIR)/r_view.app
WRAPPER=$(BINDIR)/r_view

.PHONY: app
app: node_modules
	@test -f $(ICNS) || { echo "Missing $(ICNS). Run 'make icon'."; exit 1; }
	@npm run build
	@npx electron-builder --mac --dir
	@echo "Binary is at $(BINARY)"

.PHONY: check
check: node_modules
	@npx tsc --noEmit
	@npx vitest run

.PHONY: run
run: node_modules
	@npm run build
	@npx electron dist/main.js $(FILE)

# The command line entry point is a wrapper script rather than a symlink to the
# binary. Electron finds its helper apps relative to the bundle that the exec
# path points into, and a symlink leaves it looking in the wrong directory: the
# app starts but its renderer and GPU processes die, so the window never paints.
.PHONY: install
install: app
	@mkdir -p "$(APPDIR)" "$(BINDIR)"
	@rm -rf "$(INSTALLED_APP)"
	@ditto "$(APP)" "$(INSTALLED_APP)"
	@{ \
	  echo '#!/bin/sh'; \
	  echo 'exec "$(INSTALLED_APP)/Contents/MacOS/r_view" "$$@"'; \
	} > "$(WRAPPER)"
	@chmod +x "$(WRAPPER)"
	@echo "Installed $(INSTALLED_APP)"
	@echo "Installed $(WRAPPER)"
	@case ":$$PATH:" in \
	  *":$(BINDIR):"*) ;; \
	  *) echo "Warning: $(BINDIR) is not on your PATH." ;; \
	esac

.PHONY: uninstall
uninstall:
	@rm -rf "$(INSTALLED_APP)"
	@rm -f "$(WRAPPER)"
	@echo "Removed $(INSTALLED_APP)"
	@echo "Removed $(WRAPPER)"

# The icon is generated but committed, so building never has to run this. Run it
# by hand after changing icon/draw-icon.ts, and commit the result.
.PHONY: icon
icon: node_modules
	@npm run icon

node_modules: package.json
	@npm install
	@touch node_modules

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) dist icon/r_view.iconset icon/*.js icon/*.js.map
