
ROOT        := .

SHELL       := /bin/bash

SCRIPTS     := bin/cli* bin/*-select bin/backlight-brightness
LIB_DIR     := $(ROOT)/usr/lib/shell
BIN_DIR     := $(ROOT)/usr/local/bin
LOCALE_DIR  := $(ROOT)/usr/share/
DESK_DIR    := $(ROOT)/usr/share/applications/antix
MAN_DIR     := $(ROOT)/usr/share/man/man1
RULES_DIR   := $(ROOT)/etc/udev/rules.d/

ALL_DIRS   := $(LIB_DIR) $(BIN_DIR) $(LOCALE_DIR) $(MAN_DIR) $(RULES_DIR)

.PHONY: scripts help all lib rules

help:
	@echo "make help                show this help"
	@echo "make all                 install to current directory"
	@echo "make all ROOT=           install to /"
	@echo "make all ROOT=dir        install to directory dir"
	@echo "make lib                 install the lib and aux files"
	@echo "make live-usb-maker      install live-usb-maker"
	@echo "make live-kernel-updater install live-kernel-updater"
	@#echo ""
	@#echo ""

all: scripts lib rules

lib: | $(LIB_DIR) $(LOCALE_DIR)
	cp -r lib/* $(LIB_DIR)
	@#cp -r locale $(LOCALE_DIR)

scripts: | $(BIN_DIR)
	cp $(SCRIPTS) $(BIN_DIR)

rules: | $(RULES_DIR)
	cp udev-rules/*.rules $(RULES_DIR)

$(ALL_DIRS):
	test -d $(ROOT)/
	mkdir -p $@
