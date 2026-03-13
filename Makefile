# Discover all sessions by finding directories containing a main.typ
SESSIONS := $(sort $(dir $(wildcard sessions/*/main.typ)))

# Map sessions/X.Y-name/ -> build/X.Y-name.pdf
PDFS     := $(patsubst sessions/%/,build/%.pdf,$(SESSIONS))

# Shared style — all sessions depend on it
STYLE    := sessions/style.typ

.PHONY: all clean watch

# Build all session PDFs
all: $(PDFS)

# Each PDF depends on its main.typ, all its slides, and the shared style.
# Rebuilds if any of those change.
# --root . allows sessions to import ../style.typ relative to the project root.
build/%.pdf: sessions/%/main.typ sessions/%/slides/*.typ $(STYLE) | build
	typst compile --root . $< $@

# Create the output directory on first build
build:
	mkdir -p build

# Rebuild on any .typ file change (requires entr)
watch:
	find sessions -name '*.typ' | entr make

# Remove all built artifacts
clean:
	rm -rf build
