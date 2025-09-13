SHELL := /bin/sh

# Auto-detect PO and POT files in the current directory
PO_FILES := $(wildcard *.po)
MO_FILES := $(PO_FILES:.po=.mo)
POT_FILE := $(firstword $(wildcard *.pot))

# Tools (override if needed):
MSGFMT ?= msgfmt
MSGMERGE ?= msgmerge
POCOUNT ?= pocount

.PHONY: all build check stats sync clean help

# Default target
all: build

# Compile all .po into .mo
build: $(MO_FILES)

# Pattern rule: compile a single .po into .mo
# Auto-sanitize input: drop obsolete entries and deduplicate before compiling
%.mo: %.po
	@echo "Compiling $< -> $@"
	@tmp="$@.tmp.po"; \
	  sed '/^#~/d' "$<" | msguniq --use-first > "$$tmp"; \
	  $(MSGFMT) --check-format -o "$@" "$$tmp"; \
	  rm -f "$$tmp"

# Validate .po files (syntax + format placeholders)
check:
	@set -e; \
	if [ -n "$(PO_FILES)" ]; then \
	  for f in $(PO_FILES); do \
	    echo "Checking $$f"; \
	    $(MSGFMT) -c --check-format --check-domain -o /dev/null "$$f"; \
	  done; \
	else \
	  echo "No .po files found"; \
	fi; \
	echo "OK"

# Translation stats (requires translate-toolkit's pocount)
stats:
	@if command -v $(POCOUNT) >/dev/null 2>&1; then \
	  $(POCOUNT) $(PO_FILES); \
	else \
	  echo "pocount not found; install translate-toolkit for stats"; \
	fi

# Merge POT into PO files if a POT is present
sync:
	@set -e; \
	if [ -n "$(POT_FILE)" ]; then \
	  echo "Merging POT $(POT_FILE) into PO files"; \
	  for f in $(PO_FILES); do \
	    echo "  msgmerge --update $$f $(POT_FILE)"; \
	    $(MSGMERGE) --update "$$f" "$(POT_FILE)"; \
	  done; \
	else \
	  echo "No .pot found; skipping sync"; \
	fi

# Remove compiled files
clean:
	@rm -f $(MO_FILES)

# Show available commands
help:
	@echo "Targets:"; \
	echo "  all/build  Compile .po -> .mo"; \
	echo "  check      Validate .po files"; \
	echo "  stats      Show translation stats (requires translate-toolkit)"; \
	echo "  sync       Merge POT into PO (if *.pot present)"; \
	echo "  clean      Remove compiled .mo"
