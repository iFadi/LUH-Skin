#!/bin/bash
#
# Build the LUH skin: stamp a fresh version id into template.xml and compile the SCSS
# against ILIAS's delos base style.
#
# Usage: ./update-skin.sh [env] [base_path] [ilias_root]
#   env         dev | prod (default: prod). dev also emits a source map.
#   base_path   URL prefix in front of /assets/ (default: "" for prod, ".." for dev).
#               Only needed when ILIAS is not served from the domain root.
#   ilias_root  Path to an ILIAS root (the folder containing templates/default/ and
#               ilias_version.php). Required when compiling OUTSIDE an ILIAS
#               installation; may also be given as $ILIAS_ROOT.
#
# The production server has no dart-sass: the compiled CSS is committed and deployed
# from git. Every commit that touches *.scss must therefore contain the output of this
# script (LUH-Style.css, template.xml, ILIAS_BUILD_VERSION).

set -euo pipefail

# The style id. ILIAS derives everything from it: the style folder, and the CSS file
# it loads (<skin>/<style>/<style>.css). It must match the id in tpl.xml.
style="LUH-Style"

scss_entry="${style}/scss/${style}.scss"
scss_tmp="${style}/scss/${style}.compiled.scss"
css_out="${style}/${style}.css"

# Always run from the skin root, wherever the script is called from.
cd "$(dirname "${BASH_SOURCE[0]}")"

# Never leave the transient entry file behind, also not when sass fails.
cleanup() { rm -f "$scss_tmp" "${scss_tmp}.bak"; }
trap cleanup EXIT

if ! command -v sass >/dev/null 2>&1; then
    echo "❌ dart-sass not found. Install it with: npm install -g sass" >&2
    exit 1
fi
if [[ ! -f "$scss_entry" || ! -f tpl.xml ]]; then
    echo "❌ ${scss_entry} or tpl.xml is missing — is this the skin root?" >&2
    exit 1
fi

env="${1:-}"
base_path="${2:-}"
ilias_path="${3:-${ILIAS_ROOT:-}}"

if [[ -z "$env" ]]; then
    echo "⚠️  No environment specified (dev or prod), defaulting to prod"
    env="prod"
fi
if [[ "$env" != "dev" && "$env" != "prod" ]]; then
    echo "❌ Unknown environment '$env' (expected dev or prod)" >&2
    exit 1
fi

if [[ -z "$base_path" && "$env" == "dev" ]]; then
    base_path=".."
fi
# The base path is pasted into a sed replacement and into SCSS string literals, so
# restrict it to plain URL path characters instead of trying to escape it.
if [[ ! "$base_path" =~ ^[A-Za-z0-9._~/:-]*$ ]]; then
    echo "❌ base_path may only contain URL path characters (got '$base_path')" >&2
    exit 1
fi
echo "ℹ️  Base path: '${base_path}'"

# Source maps are emitted for dev builds only. A prod build is what gets committed and
# deployed, and a committed map is harmful there: it is served publicly next to the
# CSS, while its "sources" are absolute build-host paths that leak the local directory
# layout, do not exist on the server, and churn in every diff.
if [[ "$env" == "dev" ]]; then
    build_mode="Development"
    sass_opts=()
else
    build_mode="Production"
    sass_opts=(--no-source-map)
fi

# Inject the base path (controls the runtime URL prefix of ILIAS's fonts and images).
sed "s|\$base-path: \".*\";|\$base-path: \"${base_path}\";|" "$scss_entry" > "$scss_tmp"

# Resolve the delos import.
# By default the skin is compiled IN PLACE inside an ILIAS installation
# (public/Customizing/skin/LUH-Skin/), where the relative "@use .../templates/default/delos"
# resolves against the ILIAS tree. SCSS @use paths must be static literals, so for a
# STANDALONE compile the import is rewritten in the transient entry file to an absolute
# path below the given ILIAS root.
if [[ -n "$ilias_path" ]]; then
    ilias_path="$(cd "$ilias_path" 2>/dev/null && pwd)" || {
        echo "❌ ILIAS root '${3:-${ILIAS_ROOT:-}}' does not exist" >&2
        exit 1
    }
    delos_path="${ilias_path}/templates/default/delos"
    if [[ ! -f "${delos_path}.scss" ]]; then
        echo "❌ delos not found at ${delos_path}.scss" >&2
        echo "   Pass the path to your ILIAS root (the folder containing templates/default/)" >&2
        echo "   as the 3rd argument, or via the ILIAS_ROOT environment variable." >&2
        exit 1
    fi
    echo "ℹ️  Redirecting delos import to: ${delos_path}"
    sed -i.bak -E "s|@use \"[^\"]*templates/default/delos\"|@use \"${delos_path}\"|" "$scss_tmp"
fi

# Compile to a temporary file first: a failed build must not destroy the committed CSS.
echo "Compiling ${scss_entry} (${build_mode})..."
css_tmp="${css_out}.tmp"
rm -f "$css_tmp" "${css_tmp}.map"
# ${arr[@]+...}: expanding an EMPTY array is an "unbound variable" error under `set -u`
# in bash < 4.4 (macOS still ships 3.2).
if ! sass ${sass_opts[@]+"${sass_opts[@]}"} "$scss_tmp" "$css_tmp"; then
    rm -f "$css_tmp" "${css_tmp}.map"
    echo "❌ sass failed — ${css_out} left unchanged" >&2
    exit 1
fi
# Drop a stale map from an earlier dev build so a prod build never ships a map that no
# longer matches the CSS next to it.
rm -f "${css_out}.map"
mv "$css_tmp" "$css_out"
if [[ -f "${css_tmp}.map" ]]; then
    mv "${css_tmp}.map" "${css_out}.map"
    # The map was written for the temporary name; point the CSS at the final one.
    sed -i.bak "s|${style}.css.tmp.map|${style}.css.map|" "$css_out" && rm -f "${css_out}.bak"
fi

# Record which ILIAS release this build compiled against.
#
# The compiled CSS BUNDLES the delos base of that release. A CSS built against an older
# ILIAS therefore ships no rules for components ILIAS added since — those render
# unstyled on the newer server, without any error. Writing the version down at build
# time (rather than maintaining it by hand in the README) keeps that claim honest.
#
# In-place builds run from public/Customizing/skin/LUH-Skin/, so the ILIAS root — the folder
# holding ilias_version.php — is four levels up.
version_file="${ilias_path:-../../../..}/ilias_version.php"
if [[ -f "$version_file" ]]; then
    # const ILIAS_VERSION_NUMERIC = "11.5";  ->  11.5
    ilias_version="$(sed -n 's/.*ILIAS_VERSION_NUMERIC[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$version_file" | head -n1)"
    if [[ -n "$ilias_version" ]]; then
        echo "v${ilias_version}" > ILIAS_BUILD_VERSION
        echo "ℹ️  Compiled against ILIAS v${ilias_version} (recorded in ILIAS_BUILD_VERSION)"
    else
        echo "⚠️  Could not parse ILIAS_VERSION_NUMERIC from $version_file"
        echo "   ILIAS_BUILD_VERSION left unchanged — update it by hand before committing."
    fi
else
    echo "⚠️  No ilias_version.php found at $version_file"
    echo "   ILIAS_BUILD_VERSION left unchanged — update it by hand before committing."
fi

# Stamp the version id last, so a failed build does not bump it. ILIAS appends the id
# to the stylesheet URL as a cache buster. Written to template.xml directly instead of
# `sed -i`, whose syntax differs between GNU and BSD/macOS sed.
now="$(date '+%Y%m%d-%H%M%S')"
sed "s/\\\$Id\\\$/\$${now}\$/" tpl.xml > template.xml
echo "ℹ️  Version id in template.xml set to ${now}"

echo "✅ Compilation completed: ${css_out}"
