SDK_HOME := $(shell cat "$(HOME)/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")
MONKEYC := $(SDK_HOME)/bin/monkeyc
MONKEYDO := $(SDK_HOME)/bin/monkeydo
CONNECTIQ := $(SDK_HOME)/bin/connectiq
DEVELOPER_KEY ?= $(HOME)/Library/Application Support/Garmin/ConnectIQ/developer_key.der
DEVICE ?= fr965
OUTPUT := bin/PolarFinder.prg
ICON := resources/drawables/launcher_icon.png

.PHONY: build simulator run clean

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

clean:
	rm -rf bin
