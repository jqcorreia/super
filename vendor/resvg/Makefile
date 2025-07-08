RELEASE_VERSION  = 0.45.1
RELEASE_BASENAME = resvg-$(RELEASE_VERSION)
RELEASE_ARCHIVE  = $(RELEASE_BASENAME).tar.xz

.PHONY: all clean

all: libresvg.a

clean:
	-@rm -rf "$(RELEASE_BASENAME)" 2>/dev/null
	-@rm "$(RELEASE_ARCHIVE)" 2>/dev/null

libresvg.a: $(RELEASE_ARCHIVE)
	@tar -xf $<
	@cargo build "--manifest-path=$(RELEASE_BASENAME)/Cargo.toml" --release --all
	@mv "$(RELEASE_BASENAME)/target/release/libresvg.a" "$@"

$(RELEASE_ARCHIVE):
	@wget "https://github.com/linebender/resvg/releases/download/v$(RELEASE_VERSION)/$(RELEASE_ARCHIVE)"
