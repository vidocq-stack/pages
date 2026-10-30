#!/bin/sh
# Vidocq CLI installer — https://vidocq.dev/install.sh
#
# Downloads the latest released Vidocq CLI distribution from Maven Central
# into ~/.vidocq/cli and links a `vidocq` launcher into ~/.local/bin.
#
# Usage:
#   curl -fsSL https://vidocq.dev/install.sh | sh
#   curl -fsSL https://vidocq.dev/install.sh | VIDOCQ_VERSION=0.2.1 sh      # pin a version
#   curl -fsSL https://vidocq.dev/install.sh | VIDOCQ_VERSION=snapshot sh   # latest build of main
#   curl -fsSL https://vidocq.dev/install.sh | VIDOCQ_NO_COMPLETION=1 sh    # leave ~/.zshrc / ~/.bashrc alone
set -eu

# VIDOCQ_CENTRAL override is for testing against a repository mirror.
CENTRAL="${VIDOCQ_CENTRAL:-https://repo1.maven.org/maven2}/io/vidocq/runtime/vidocq-runtime-cli"
# Every build of main publishes its SNAPSHOTs there.
SNAPSHOTS="${VIDOCQ_SNAPSHOTS:-https://maven.vidocq.dev/snapshots}/io/vidocq/runtime/vidocq-runtime-cli"
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

# Split on version separators too, so early-access versions such as 28-ea
# retain their numeric major version.
JAVA_MAJOR=$(java -version 2>&1 | awk -F'"' '/version/ {split($2, v, /[.+-]/); print (v[1] == "1") ? v[2] : v[1]; exit}')
case "$JAVA_MAJOR" in
    ''|*[!0-9]*) fail "Could not parse the local Java version (java -version)." ;;
esac
[ "$JAVA_MAJOR" -ge 25 ] || fail "Java 25+ is required (found Java $JAVA_MAJOR).
  Install it with SDKMAN!: sdk install java 25-tem"
ok "Java $JAVA_MAJOR detected"

# ── Resolve the version ────────────────────────────────────────
if [ "${VIDOCQ_VERSION:-}" = "snapshot" ]; then
    say "Resolving the latest SNAPSHOT from the Central snapshot repository..."
    VERSION=$(curl -fsSL --retry 3 "$SNAPSHOTS/maven-metadata.xml" \
        | sed -n 's/.*<version>\(.*-SNAPSHOT\)<\/version>.*/\1/p' \
        | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1)
    [ -n "$VERSION" ] || fail "Could not resolve the latest SNAPSHOT from the snapshot metadata."
    ok "Latest SNAPSHOT: $VERSION"
elif [ -n "${VIDOCQ_VERSION:-}" ]; then
    VERSION="$VIDOCQ_VERSION"
    say "Using pinned version $VERSION"
else
    say "Resolving the latest release from Maven Central..."
    VERSION=$(curl -fsSL --retry 3 "$CENTRAL/maven-metadata.xml" \
        | sed -n 's/.*<release>\(.*\)<\/release>.*/\1/p' | head -n 1)
    [ -n "$VERSION" ] || fail "Could not resolve the latest release from Central metadata."
    ok "Latest release: $VERSION"
fi

# ── Download and unpack ────────────────────────────────────────
case "$VERSION" in
    *-SNAPSHOT)
        # A SNAPSHOT zip is stored under a timestamped name and changes with every
        # build of main: always download it again.
        STAMP=$(curl -fsSL --retry 3 "$SNAPSHOTS/$VERSION/maven-metadata.xml" | tr -d ' \t\r\n' \
            | sed -n 's/.*<classifier>cli<\/classifier><extension>zip<\/extension><value>\([^<]*\)<\/value>.*/\1/p')
        [ -n "$STAMP" ] || fail "No $VERSION distribution zip in the snapshot metadata."
        ok "Build $STAMP"
        DIST_URL="$SNAPSHOTS/$VERSION/vidocq-runtime-cli-$STAMP-cli.zip"
        REFRESH=1
        ;;
    *)
        DIST_URL="$CENTRAL/$VERSION/vidocq-runtime-cli-$VERSION-cli.zip"
        REFRESH=0
        ;;
esac
TARGET="$INSTALL_ROOT/$VERSION"

if [ "$REFRESH" = 0 ] && [ -x "$TARGET/bin/vidocq" ]; then
    ok "Vidocq CLI $VERSION is already installed in $TARGET"
else
    TMP_ZIP=$(mktemp) || fail "mktemp failed"
    trap 'rm -f "$TMP_ZIP"' EXIT
    say "Downloading ${DIST_URL}..."
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

# ── Shell completion ───────────────────────────────────────────
# `vidocq completion install` writes the script under ~/.vidocq/completion and
# sources it from ~/.zshrc or ~/.bashrc, the shell taken from $SHELL; running
# it again never duplicates the block. A CLI older than the command, or another
# shell, just leaves completion off: it never fails the install.
if [ -n "${VIDOCQ_NO_COMPLETION:-}" ]; then
    say "Shell completion skipped (VIDOCQ_NO_COMPLETION is set)"
elif "$TARGET/bin/vidocq" completion install >/dev/null 2>&1; then
    ok "Shell completion enabled — open a new terminal (undo: vidocq completion uninstall)"
else
    say "Shell completion not set up (it needs bash or zsh, and a CLI with 'vidocq completion install')"
fi

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
