ifeq ($(origin SDK_HOME), undefined)
SDK_HOME := $(shell cat "$(HOME)/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")
endif
MONKEYC := $(SDK_HOME)/bin/monkeyc
MONKEYDO := $(SDK_HOME)/bin/monkeydo
CONNECTIQ := $(SDK_HOME)/bin/connectiq
DEVELOPER_KEY ?= $(HOME)/Library/Application Support/Garmin/ConnectIQ/developer_key.der
UV ?= uv
MONKEYC_FMT ?= monkeyc-fmt
DEVICE ?= fr965
DEVICES := fr255 fr255s fr255m fr255sm fr965
TEST_DEVICES := fr255s fr255 fr965
# The compiler writes intermediate files beside its output; isolate each device.
OUTPUT := bin/$(DEVICE)/PolarFinder-$(DEVICE).prg
TEST_OUTPUT := bin/PolarFinder-tests-$(DEVICE).prg
PACKAGE_OUTPUT := bin/PolarFinder.iq
ICON_454 := resources/drawables/launcher_icon.png
ICON_218 := resources-round-218x218/drawables/launcher_icon.png
TEST_JUNGLES := monkey.jungle:test.jungle
ICON_260 := resources-round-260x260/drawables/launcher_icon.png
ICONS := $(ICON_454) $(ICON_218) $(ICON_260)

.PHONY: build build-all package simulator run format lint test test-profiles clean icons generate-iers check-generated update-iers $(DEVICES:%=build-%) $(TEST_DEVICES:%=test-%)

icons: $(ICONS)

build: $(ICONS)
	mkdir -p "$(dir $(OUTPUT))"
	"$(MONKEYC)" -d "$(DEVICE)" -f monkey.jungle -o "$(OUTPUT)" -y "$(DEVELOPER_KEY)"

build-all: $(DEVICES:%=build-%)

$(DEVICES:%=build-%): build-%: $(ICONS)
	mkdir -p "bin/$*"
	"$(MONKEYC)" -d "$*" -f monkey.jungle -o "bin/$*/PolarFinder-$*.prg" -y "$(DEVELOPER_KEY)"

package: $(ICONS)
	mkdir -p bin
	"$(MONKEYC)" -e -f monkey.jungle -o "$(PACKAGE_OUTPUT)" -y "$(DEVELOPER_KEY)"

test: format $(ICONS)
	mkdir -p bin
	"$(MONKEYC)" -t -d "$(DEVICE)" -f "$(TEST_JUNGLES)" -o "$(TEST_OUTPUT)" -y "$(DEVELOPER_KEY)"
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
	if [ $$validation -ne 0 ]; then exit 1; fi; \
	if [ $$runner -ne 0 ]; then \
		echo "monkeydo returned $$runner after a validated passing summary; accepting known test-runner status quirk." >&2; \
	fi

# MonkeyDo clients share one simulator; serialize even when the caller uses -j.
test-profiles:
	$(MAKE) --no-print-directory -j1 $(TEST_DEVICES:%=test-%)

$(TEST_DEVICES:%=test-%): test-%:
	$(MAKE) --no-print-directory DEVICE="$*" test

$(ICON_454): artwork/launcher-icon.svg
	mkdir -p "$(dir $@)"
	magick -background none "$<" -resize 65x65 "$@"

$(ICON_218) $(ICON_260): artwork/launcher-icon.svg
	mkdir -p "$(dir $@)"
	magick -background none "$<" -resize 40x40 -colors 64 -dither FloydSteinberg "$@"

simulator:
	"$(CONNECTIQ)"

run: build
	"$(MONKEYDO)" "$(OUTPUT)" "$(DEVICE)"

format:
	git ls-files -z --cached --others --exclude-standard -- '*.mc' | xargs -0 "$(MONKEYC_FMT)" --write

lint:
	git ls-files -z --cached --others --exclude-standard -- '*.mc' | xargs -0 "$(MONKEYC_FMT)" --check
	npx --yes --package=prettier@3.6.2 --package=@prettier/plugin-xml@3.4.2 sh -c 'prettier --plugin="$$(dirname "$$(dirname "$$(command -v prettier)")")/@prettier/plugin-xml/src/plugin.js" --tab-width=2 --use-tabs=false --xml-whitespace-sensitivity=ignore --check "**/*.xml"'

generate-iers:
	MONKEYC_FMT="$(MONKEYC_FMT)" $(UV) run --script tools/iers.py generate

check-generated:
	MONKEYC_FMT="$(MONKEYC_FMT)" $(UV) run --script tools/iers.py check

update-iers:
	MONKEYC_FMT="$(MONKEYC_FMT)" $(UV) run --script tools/iers.py update


clean:
	rm -rf bin
