#!/bin/bash
# claude-clone: make a second, isolated copy of Claude Desktop with its own account.
set -euo pipefail

VERSION="1.0.0"
SOURCE="/Applications/Claude.app"
NAME=""
LABEL=""
COLOR=""
LABEL_SET=0
YES=0
DEFAULT_NAME="Claude Personal"
DEFAULT_COLOR="#1F2937"
PB=/usr/libexec/PlistBuddy
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

usage() {
  cat <<USAGE
Usage: claude-clone.sh [options]

Creates an isolated copy of Claude Desktop with a separate account.

Options:
  --name NAME     App name (default: "$DEFAULT_NAME")
  --label LABEL   Icon badge text (default: name without "Claude"; "-" keeps the original icon)
  --color HEX     Badge color, with or without # (default: $DEFAULT_COLOR)
  --source PATH   Claude app to copy (default: $SOURCE)
  --yes           Skip the confirmation prompt
  --version       Print version
  --help          Print this help
USAGE
}

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

# ask PROMPT DEFAULT -> sets REPLY (default on empty input or EOF)
ask() {
  read -r -p "$1" REPLY || REPLY=""
  [ -n "$REPLY" ] || REPLY="$2"
}

# normalise_color HEX -> prints #RRGGBB or fails
normalise_color() {
  local c="${1#\#}"
  [[ "$c" =~ ^[0-9A-Fa-f]{6}$ ]] || return 1
  echo "#$c"
}

plist_set() { # key value
  "$PB" -c "Set :$1 $2" "$PLIST" 2>/dev/null || "$PB" -c "Add :$1 string $2" "$PLIST"
}

[ "$(uname)" = "Darwin" ] || die "this script only runs on macOS"

while [ $# -gt 0 ]; do
  case "$1" in
    --name|--label|--color|--source)
      [ $# -ge 2 ] || { echo "error: $1 needs a value" >&2; usage >&2; exit 2; }
      case "$1" in
        --name) NAME="$2" ;;
        --label) LABEL="$2"; LABEL_SET=1 ;;
        --color) COLOR="$2" ;;
        --source) SOURCE="$2" ;;
      esac
      shift 2 ;;
    --yes) YES=1; shift ;;
    --version) echo "claude-clone $VERSION"; exit 0 ;;
    --help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Validate flag values before asking anything
if [ -n "$COLOR" ]; then
  COLOR=$(normalise_color "$COLOR") || die "color must be 6 hex digits, e.g. #1F2937"
fi
SOURCE="${SOURCE%/}"

if [ -z "$NAME" ]; then
  ask "[1/3] App name [$DEFAULT_NAME]: " "$DEFAULT_NAME"
  NAME="$REPLY"
fi
case "$NAME" in */*|*:*) die "name must not contain / or :" ;; esac

SLUG=$(echo "$NAME" | tr ' ' '-' | LC_ALL=C tr -cd 'A-Za-z0-9-' | tr -s '-' | sed 's/^-*//;s/-*$//')
[ -n "$SLUG" ] || die "name must contain ASCII letters or digits"

if [ "$LABEL_SET" -eq 0 ]; then
  default_label=$(echo "${NAME//Claude/}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -n "$default_label" ]; then
    ask "[2/3] Icon label [$default_label] (- keeps the original icon): " "$default_label"
  else
    ask "[2/3] Icon label [-] (- keeps the original icon): " "-"
  fi
  LABEL="$REPLY"
fi
[ -n "$LABEL" ] || LABEL="-"

if [ "$LABEL" != "-" ] && [ -z "$COLOR" ]; then
  while :; do
    ask "[3/3] Badge color (hex) [$DEFAULT_COLOR]: " "$DEFAULT_COLOR"
    if COLOR=$(normalise_color "$REPLY"); then break; fi
    echo "Invalid color, expected 6 hex digits." >&2
  done
fi

TARGET="/Applications/$NAME.app"
BUNDLE_ID="com.anthropic.claude.clone.$SLUG"
DATA_DIR="$HOME/Library/Application Support/$SLUG"
PLIST="$TARGET/Contents/Info.plist"

[ "$TARGET" != "$SOURCE" ] || die "target equals source"
[ -f "$SOURCE/Contents/Info.plist" ] || die "source not found or has no Info.plist: $SOURCE"
[ -w /Applications ] || die "/Applications is not writable"

echo "App:       $TARGET"
echo "Bundle ID: $BUNDLE_ID"
echo "Data:      $DATA_DIR"
if [ "$LABEL" = "-" ]; then
  echo "Icon:      original icon"
else
  echo "Label:     $LABEL"
  echo "Color:     $COLOR"
fi
if [ "$YES" -eq 0 ]; then
  read -r -p "Continue? [y/N] " REPLY || REPLY=""
  case "$REPLY" in y|Y|yes) ;; *) echo "Aborted."; exit 1 ;; esac
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

log "Checking for a running clone"
if pgrep -f "$TARGET/Contents/MacOS/" >/dev/null; then
  die "$NAME is running, quit it first"
fi

if [ -e "$TARGET" ]; then
  existing=$("$PB" -c "Print :CFBundleIdentifier" "$PLIST" 2>/dev/null || true)
  case "$existing" in
    com.anthropic.claude.clone.*) log "Removing previous clone"; rm -rf "$TARGET" ;;
    *) die "$TARGET exists and is not a claude-clone app, refusing to delete it" ;;
  esac
fi

log "Copying $SOURCE"
ditto "$SOURCE" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

log "Updating Info.plist"
# Keep CFBundleName: Electron looks up "Frameworks/<CFBundleName> Helper.app" and aborts with
# "Unable to find helper app" if it changes. Display name + file name are what Finder/Dock show.
plist_set CFBundleDisplayName "$NAME"
plist_set CFBundleIdentifier "$BUNDLE_ID"

if [ "$LABEL" != "-" ]; then
  log "Building icon"
  icon=$("$PB" -c "Print :CFBundleIconFile" "$PLIST")
  case "$icon" in *.*) ;; *) icon="$icon.icns" ;; esac
  sips -s format png -z 1024 1024 "$TARGET/Contents/Resources/$icon" --out "$TMP/in.png" >/dev/null
  if ! err=$(osascript -l JavaScript - "$TMP/in.png" "$TMP/out.png" "$LABEL" "$COLOR" 2>&1 <<'JS'
ObjC.import('AppKit');
ObjC.import('CoreGraphics');
function run(argv) {
  var img = $.NSImage.alloc.initWithContentsOfFile($(argv[0]));
  if (img.isNil()) throw new Error('cannot load ' + argv[0]);
  var rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, 1024, 1024, 8, 4, true, false, $.NSCalibratedRGBColorSpace, 0, 0);
  $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
  img.drawInRectFromRectOperationFraction($.NSMakeRect(0, 0, 1024, 1024), $.NSZeroRect, $.NSCompositingOperationSourceOver, 1.0);

  var hex = argv[3].replace('#', '');
  var rgb = [0, 2, 4].map(function (i) { return parseInt(hex.substr(i, 2), 16) / 255; });
  var bx = 140, by = 150, bw = 744, bh = 150;
  var cg = $.NSGraphicsContext.currentContext.CGContext;
  $.CGContextSetRGBFillColor(cg, rgb[0], rgb[1], rgb[2], 1);
  $.CGContextAddPath(cg, $.CGPathCreateWithRoundedRect($.CGRectMake(bx, by, bw, bh), 40, 40, null));
  $.CGContextFillPath(cg);

  var text = $(argv[2]);
  var attrs = $.NSMutableDictionary.alloc.init;
  attrs.setObjectForKey($.NSColor.whiteColor, $.NSForegroundColorAttributeName);
  var size = 120, w, h;
  for (;;) {
    attrs.setObjectForKey($.NSFont.boldSystemFontOfSize(size), $.NSFontAttributeName);
    var s = text.sizeWithAttributes(attrs);
    w = s.width; h = s.height;
    if (w <= bw - 80 || size <= 16) break;
    size -= 2;
  }
  text.drawAtPointWithAttributes($.NSMakePoint(bx + (bw - w) / 2, by + (bh - h) / 2), attrs);

  var data = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $());
  if (!data.writeToFileAtomically($(argv[1]), true)) throw new Error('cannot write ' + argv[1]);
}
JS
  ); then
    echo "$err" >&2
    die "badge drawing failed; rerun with --label - to keep the original icon"
  fi

  set_dir="$TMP/icon.iconset"
  mkdir "$set_dir"
  for s in 16 32 128 256 512; do
    sips -z "$s" "$s" "$TMP/out.png" --out "$set_dir/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$TMP/out.png" --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$set_dir" -o "$TARGET/Contents/Resources/claude-clone.icns"
  plist_set CFBundleIconFile claude-clone.icns
  "$PB" -c "Delete :CFBundleIconName" "$PLIST" 2>/dev/null || true
fi

log "Installing executable wrapper"
EXE=$("$PB" -c "Print :CFBundleExecutable" "$PLIST")
mv "$TARGET/Contents/MacOS/$EXE" "$TARGET/Contents/MacOS/$EXE.real"
cat > "$TARGET/Contents/MacOS/$EXE" <<WRAP
#!/bin/zsh
exec "\${0:A:h}/$EXE.real" --user-data-dir="\$HOME/Library/Application Support/$SLUG" "\$@"
WRAP
chmod 755 "$TARGET/Contents/MacOS/$EXE"

log "Re-signing (ad-hoc, inside-out)"
sign() {
  local out
  out=$(codesign --force --sign - "$1" 2>&1) || { echo "$out" >&2; die "codesign failed: $1"; }
}
while IFS= read -r -d '' f; do
  [ "$f" = "$TARGET" ] || sign "$f"
done < <(find "$TARGET/Contents" -depth \( -name '*.dylib' -o -name '*.framework' -o -name '*.app' \) -print0)
if [ -d "$TARGET/Contents/Helpers" ]; then
  while IFS= read -r -d '' f; do
    sign "$f"
  done < <(find "$TARGET/Contents/Helpers" -maxdepth 1 -type f -print0)
fi
sign "$TARGET/Contents/MacOS/$EXE.real"
sign "$TARGET"
if ! out=$(codesign --verify --deep --strict "$TARGET" 2>&1); then
  echo "$out" >&2
  die "signature verification failed"
fi

log "Registering app"
"$LSREGISTER" -f "$TARGET"
killall Dock 2>/dev/null || true

echo
echo "Done: $TARGET"
echo "Data folder: $DATA_DIR (created by Claude on first launch)"
echo "On first sign-in, close the original Claude: the claude:// login link opens whichever Claude is running."
echo "Re-run this command after each Claude update (account data is kept)."
