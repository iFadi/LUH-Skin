#!/bin/bash

set -e

echo "--------------------"
echo "Updating version-id in template.xml"
now=$(date '+%Y%m%d-%H%M%S')
echo "$now"

templatePath="tpl.xml"
cp "$templatePath" template.xml
id='Id'
sed -i -e "s/$id/$now/g" template.xml
echo "Version-id in template.xml is set to $now"
echo "--------------------"

echo "Compiling SASS files for ILIAS skin..."

# Remove the old CSS file
echo "Removing old LUH-Style.css..."
rm -f LUH-Style/LUH-Style.css

# Read environment and base path from arguments
env="$1"
base_path="$2"

# Default values if not provided
if [[ -z "$env" ]]; then
    echo "⚠️  No environment specified (dev or prod), defaulting to prod"
    env="prod"
fi

if [[ -z "$base_path" ]]; then
    if [[ "$env" == "dev" ]]; then
        base_path="/ilias-luh/"
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

# Replace the $base-path value dynamically (if it exists in the SCSS file)
echo "Injecting base path..."
if grep -q "\$base-path:" LUH-Style/scss/LUH-Style.scss; then
    sed "s|\$base-path: \".*\";|\$base-path: \"$base_path\";|" \
        LUH-Style/scss/LUH-Style.scss > LUH-Style/scss/LUH-Style.compiled.scss
else
    # If $base-path doesn't exist, just copy the file
    cp LUH-Style/scss/LUH-Style.scss LUH-Style/scss/LUH-Style.compiled.scss
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
