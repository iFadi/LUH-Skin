#!/bin/bash

set -e

echo "--------------------"
echo "Updating version-id in template.xml"
now=$(date '+%Y%m%d-%H%M%S')
echo "$now"

templatePath="tpl.xml"
id='Id'
# Portable in-place rewrite: write directly to template.xml instead of `sed -i`,
# whose syntax differs between GNU and BSD/macOS sed (the latter would otherwise
# leave a stray template.xml-e backup file behind on every run).
sed "s/$id/$now/g" "$templatePath" > template.xml
echo "Version-id in template.xml is set to $now"
echo "--------------------"

echo "Compiling SASS files for ILIAS skin..."

# Remove the old CSS file (and any stale source map from a previous dev build, so a
# prod build never leaves a map that no longer matches the CSS next to it)
echo "Removing old LUH-Style.css..."
rm -f LUH-Style/LUH-Style.css LUH-Style/LUH-Style.css.map

# Read environment and base path from arguments
env="$1"
base_path="$2"
# Optional path to an ILIAS root (the folder containing templates/default/) used to resolve
# the delos import when compiling OUTSIDE an ILIAS installation (standalone / local dev).
# May also be supplied via the ILIAS_ROOT environment variable.
ilias_path="${3:-${ILIAS_ROOT:-}}"

# Default values if not provided
if [[ -z "$env" ]]; then
    echo "⚠️  No environment specified (dev or prod), defaulting to prod"
    env="prod"
fi

if [[ -z "$base_path" ]]; then
    if [[ "$env" == "dev" ]]; then
        base_path=".."
    else
        base_path=""
    fi
    echo "ℹ️  No base path provided, using default: $base_path"
else
    echo "ℹ️  Using provided base path: $base_path"
fi

# Set build mode.
#
# Source maps are emitted for dev builds only. A prod build is what gets committed and
# deployed (the production server has no dart-sass, so the CSS ships precompiled from
# git), and a committed map is actively harmful there:
#   * it is served publicly next to the CSS, yet its "sources" are absolute build-host
#     paths that leak the local directory layout and do not exist on the server;
#   * a standalone compile rewrites the delos @use to an absolute path, so those paths
#     differ per build host and the 150 KB map churns in every diff.
if [[ "$env" == "dev" ]]; then
    build_mode="Development"
    sass_opts=()
else
    build_mode="Production"
    sass_opts=(--no-source-map)
fi

# Replace the $base-path value dynamically (controls the runtime FONT/IMAGE URL prefix)
echo "Injecting base path..."
sed "s|\$base-path: \".*\";|\$base-path: \"$base_path\";|" \
    LUH-Style/scss/LUH-Style.scss > LUH-Style/scss/LUH-Style.compiled.scss

# Resolve the delos import.
# By default the skin is compiled IN PLACE inside an ILIAS installation
# (public/Customizing/skin/<skin>/), where the relative "@use .../templates/default/delos"
# resolves against the ILIAS tree. SCSS @use paths must be static literals, so for a
# STANDALONE / local compile we rewrite that import in the generated *.compiled.scss to an
# absolute path, using the ILIAS root passed as the 3rd argument (or $ILIAS_ROOT).
if [[ -n "$ilias_path" ]]; then
    delos_path="${ilias_path%/}/templates/default/delos"
    if [[ ! -f "${delos_path}.scss" ]]; then
        echo "❌ delos not found at ${delos_path}.scss"
        echo "   Pass the path to your ILIAS root (the folder containing templates/default/)"
        echo "   as the 3rd argument, or via the ILIAS_ROOT environment variable."
        rm -f LUH-Style/scss/LUH-Style.compiled.scss
        exit 1
    fi
    echo "ℹ️  Redirecting delos import to: ${delos_path}"
    sed -i.bak -E "s|@use \"[^\"]*templates/default/delos\"|@use \"${delos_path}\"|" \
        LUH-Style/scss/LUH-Style.compiled.scss
    rm -f LUH-Style/scss/LUH-Style.compiled.scss.bak
fi

# Record which ILIAS release this build compiled against.
#
# The compiled LUH-Style.css BUNDLES the delos base of that release, and the skin is
# deployed precompiled from git. A CSS built against an older ILIAS therefore ships no
# rules for components ILIAS added since — those render unstyled on the newer server,
# without any error. Writing the version down at build time (rather than maintaining it
# by hand in the README) is what keeps that claim honest.
#
# In-place builds run from public/Customizing/skin/<skin>/, so the ILIAS root — the folder
# holding ilias_version.php — is four levels up. A standalone build takes it from
# $ilias_path instead.
ilias_root="${ilias_path:-../../../..}"
version_file="${ilias_root%/}/ilias_version.php"
if [[ -f "$version_file" ]]; then
    # const ILIAS_VERSION_NUMERIC = "10.9";  ->  10.9
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

# Compile with SASS
echo "Compiling with sass..."
sass "${sass_opts[@]}" LUH-Style/scss/LUH-Style.compiled.scss LUH-Style/LUH-Style.css

# Cleanup
rm LUH-Style/scss/LUH-Style.compiled.scss

echo "✅ Compilation completed!"
echo "👉 Output: LUH-Style/LUH-Style.css"
echo "🔧 Mode: $build_mode"
echo "--------------------"
