# Discover all sessions by finding directories containing a main.typ
SESSIONS := $(sort $(dir $(wildcard sessions/*/main.typ)))

# Map sessions/X.Y-name/ -> build/X.Y-name.pdf
SESSION_PDFS := $(patsubst sessions/%/,build/%.pdf,$(SESSIONS))

# Discover all labs by finding directories containing a main.typ
LABS     := $(sort $(dir $(wildcard labs/*/main.typ)))
LAB_PDFS := $(patsubst labs/%/,build/lab-%.pdf,$(LABS))

# Discover labs that have an assets folder
LAB_ASSETS   := $(sort $(dir $(wildcard labs/*/assets/)))
LAB_ARCHIVES := $(patsubst labs/%/assets/,build/lab-%-assets.tar.gz,$(LAB_ASSETS))

# Shared styles
SESSION_STYLE := sessions/style.typ
LAB_STYLE     := labs/style.typ

.PHONY: all clean watch

# Build everything
all: $(SESSION_PDFS) $(LAB_PDFS) $(LAB_ARCHIVES) build/index.html

# Each session PDF depends on its main.typ, all its sections, and the shared style.
build/%.pdf: sessions/%/main.typ sessions/%/sections/*.typ $(SESSION_STYLE) | build
	typst compile --root . $< $@

# Each lab PDF depends on its main.typ and the lab style.
build/lab-%.pdf: labs/%/main.typ $(LAB_STYLE) | build
	typst compile --root . $< $@

# Lab asset archives
build/lab-%-assets.tar.gz: labs/%/assets/* | build
	tar -czf $@ -C labs/$*/assets .

# Landing page
build/index.html: index.html | build
	cp $< $@

# Create the output directory on first build
build:
	mkdir -p build

# Rebuild on any .typ file change (requires entr)
watch:
	while true; do find sessions labs -name '*.typ' | entr -d -s 'make -k'; done

# Remove all built artifacts
clean:
	rm -rf build
