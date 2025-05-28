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

# Set base path depending on argument
if [[ "$1" == "dev" ]]; then
    echo "⚙️  Using development base path: /ilias-luh"
    base_path="/ilias-luh"
else
    echo "⚙️  Using production base path: /"
    base_path="/"
fi

# Replace the $base-path value dynamically
echo "Injecting base path..."
sed "s|\$base-path: \"/\";|\$base-path: \"$base_path\";|" \
    LUH-Style/scss/LUH-Style.scss > LUH-Style/scss/LUH-Style.compiled.scss

# Compile with SASS
echo "Compiling with sass..."
sass LUH-Style/scss/LUH-Style.compiled.scss LUH-Style/LUH-Style.css

# Cleanup
rm LUH-Style/scss/LUH-Style.compiled.scss

echo "...done!"
echo "--------------------"
