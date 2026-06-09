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

# Remove the old CSS file
echo "Removing old LUH-Style.css..."
rm -f LUH-Style/LUH-Style.css

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

# Set build mode
if [[ "$env" == "dev" ]]; then
    build_mode="Development"
else
    build_mode="Production"
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

# Compile with SASS
echo "Compiling with sass..."
sass LUH-Style/scss/LUH-Style.compiled.scss LUH-Style/LUH-Style.css

# Cleanup
rm LUH-Style/scss/LUH-Style.compiled.scss

echo "✅ Compilation completed!"
echo "👉 Output: LUH-Style/LUH-Style.css"
echo "🔧 Mode: $build_mode"
echo "--------------------"
