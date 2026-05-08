export PATH := bin:$(PATH)

SCREENCASTS_DIR := screencasts

outputs := $(foreach file, $(wildcard $(SCREENCASTS_DIR)/*.asc), $(patsubst %.asc,%.cast,$(file)))

casts: $(outputs)

$(SCREENCASTS_DIR)/%.cast: $(SCREENCASTS_DIR)/%.asc
	asciinema-rec_script $(patsubst %.cast,%.asc,$@)

casts_upload:
	upload.sh

list:
	ls $(SCREENCASTS_DIR)

clean:
	$(RM) $(SCREENCASTS_DIR)/*.cast

ARCH    ?= $(shell uname -m)
VERSION := $(shell cat version.txt)

.PHONY: dist clean-dist

dist:
	mkdir -p dist
	podman run --rm \
	    --user root \
	    -v $(CURDIR):/src:ro,Z \
	    -v $(CURDIR)/dist:/dist:Z \
	    -e ARCH=$(ARCH) \
	    --entrypoint bash \
	    registry.access.redhat.com/hi/core-runtime:latest-builder /src/scripts/build-dist.sh

clean-dist:
	$(RM) -r dist
