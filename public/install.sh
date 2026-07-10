#!/bin/sh
# Vidocq CLI installer — https://vidocq.dev/install.sh
#
# Downloads the latest released Vidocq CLI distribution from Maven Central
# into ~/.vidocq/cli and links a `vidocq` launcher into ~/.local/bin.
#
# Usage:
#   curl -fsSL https://vidocq.dev/install.sh | sh
#   VIDOCQ_VERSION=0.2.1 curl -fsSL https://vidocq.dev/install.sh | sh   # pin a version
set -eu

# VIDOCQ_CENTRAL override is for testing against a repository mirror.
CENTRAL="${VIDOCQ_CENTRAL:-https://repo1.maven.org/maven2}/io/vidocq/runtime/vidocq-runtime-cli"
INSTALL_ROOT="${VIDOCQ_HOME:-$HOME/.vidocq}/cli"
BIN_DIR="${VIDOCQ_BIN:-$HOME/.local/bin}"

say()  { printf '\033[36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✔\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✘ %s\033[0m\n' "$1" >&2; exit 1; }

# ── Prerequisites ──────────────────────────────────────────────
command -v curl  >/dev/null 2>&1 || fail "curl is required."
command -v unzip >/dev/null 2>&1 || fail "unzip is required."
command -v java  >/dev/null 2>&1 || fail "Java 25+ is required but no 'java' was found.
  Install it with SDKMAN!: curl -s https://get.sdkman.io | bash && sdk install java 25-tem"

JAVA_MAJOR=$(java -version 2>&1 | awk -F'"' '/version/ {split($2, v, "."); print (v[1] == "1") ? v[2] : v[1]; exit}')
case "$JAVA_MAJOR" in
    ''|*[!0-9]*) fail "Could not parse the local Java version (java -version)." ;;
esac
[ "$JAVA_MAJOR" -ge 25 ] || fail "Java 25+ is required (found Java $JAVA_MAJOR).
  Install it with SDKMAN!: sdk install java 25-tem"
ok "Java $JAVA_MAJOR detected"

# ── Resolve the version ────────────────────────────────────────
if [ -n "${VIDOCQ_VERSION:-}" ]; then
    VERSION="$VIDOCQ_VERSION"
    say "Using pinned version $VERSION"
else
    say "Resolving the latest release from Maven Central…"
    VERSION=$(curl -fsSL --retry 3 "$CENTRAL/maven-metadata.xml" \
        | sed -n 's/.*<release>\(.*\)<\/release>.*/\1/p' | head -n 1)
    [ -n "$VERSION" ] || fail "Could not resolve the latest release from Central metadata."
    ok "Latest release: $VERSION"
fi

# ── Download and unpack ────────────────────────────────────────
DIST_URL="$CENTRAL/$VERSION/vidocq-runtime-cli-$VERSION-cli.zip"
TARGET="$INSTALL_ROOT/$VERSION"

if [ -x "$TARGET/bin/vidocq" ]; then
    ok "Vidocq CLI $VERSION is already installed in $TARGET"
else
    TMP_ZIP=$(mktemp) || fail "mktemp failed"
    trap 'rm -f "$TMP_ZIP"' EXIT
    say "Downloading $DIST_URL…"
    curl -fSL --retry 3 -o "$TMP_ZIP" "$DIST_URL" \
        || fail "Download failed — the $VERSION distribution zip may not be published yet."
    rm -rf "$TARGET"
    mkdir -p "$TARGET"
    unzip -q "$TMP_ZIP" -d "$TARGET"
    chmod +x "$TARGET/bin/vidocq"
    ok "Installed in $TARGET"
fi

# ── Launcher on the PATH ───────────────────────────────────────
# A wrapper rather than a symlink: the distribution launcher locates its
# modules/ directory relative to its own real path.
mkdir -p "$BIN_DIR"
printf '#!/bin/sh\nexec "%s/bin/vidocq" "$@"\n' "$TARGET" > "$BIN_DIR/vidocq"
chmod +x "$BIN_DIR/vidocq"
ok "Installed launcher $BIN_DIR/vidocq"

case ":$PATH:" in
    *":$BIN_DIR:"*)
        ok "Done. Try: vidocq version"
        ;;
    *)
        say "$BIN_DIR is not on your PATH. Add it to your shell profile:"
        printf '    export PATH="%s:$PATH"\n' "$BIN_DIR"
        say "Then try: vidocq version"
        ;;
esac
