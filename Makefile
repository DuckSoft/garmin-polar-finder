SDK_HOME := $(shell cat "$(HOME)/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")
MONKEYC := $(SDK_HOME)/bin/monkeyc
MONKEYDO := $(SDK_HOME)/bin/monkeydo
CONNECTIQ := $(SDK_HOME)/bin/connectiq
DEVELOPER_KEY ?= $(HOME)/Library/Application Support/Garmin/ConnectIQ/developer_key.der
DEVICE ?= fr965
OUTPUT := bin/PolarFinder.prg
ICON := resources/drawables/launcher_icon.png

.PHONY: build simulator run lint test clean

TEST_OUTPUT := bin/PolarFinder-tests.prg

test: $(ICON)
	mkdir -p bin
	"$(MONKEYC)" -t -d "$(DEVICE)" -f monkey.jungle -o "$(TEST_OUTPUT)" -y "$(DEVELOPER_KEY)"
	@tmp="$$(mktemp "$${TMPDIR:-/tmp}/polarfinder-test.XXXXXX")"; \
	trap 'rm -f "$$tmp"' EXIT HUP INT TERM; \
	set -o pipefail; \
	"$(MONKEYDO)" "$(TEST_OUTPUT)" "$(DEVICE)" -t 2>&1 | tee "$$tmp"; \
	runner=$$?; \
	awk 'BEGIN { ok=0; bad=0 } \
	     /PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)/ { ok=1 } \
	     /FAILED|ERROR|Exception|[Tt]imeout|[Cc]rash/ { bad=1 } \
	     END { exit !(ok && !bad) }' "$$tmp"; \
	validation=$$?; \
	if [ $$validation -ne 0 ]; then \
		exit 1; \
	fi; \
	if [ $$runner -ne 0 ]; then \
		echo "monkeydo returned $$runner after a validated passing summary; accepting known test-runner status quirk." >&2; \
	fi

build: $(ICON)
	mkdir -p bin
	"$(MONKEYC)" -d "$(DEVICE)" -f monkey.jungle -o "$(OUTPUT)" -y "$(DEVELOPER_KEY)"

$(ICON): artwork/launcher-icon.svg
	mkdir -p "$(dir $@)"
	magick -background none "$<" -resize 65x65 "$@"

simulator:
	"$(CONNECTIQ)"

run: build
	"$(MONKEYDO)" "$(OUTPUT)" "$(DEVICE)"

lint:
	npx --yes --package=prettier@3.6.2 --package=@prettier/plugin-xml@3.4.2 sh -c 'prettier --plugin="$$(dirname "$$(dirname "$$(command -v prettier)")")/@prettier/plugin-xml/src/plugin.js" --tab-width=2 --use-tabs=false --xml-whitespace-sensitivity=ignore --check "**/*.xml"'

clean:
	rm -rf bin
