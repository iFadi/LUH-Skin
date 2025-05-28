#!/bin/bash

echo "--------------------"
echo "Updating version-id in template.xml"
# get current date and time
now=$(date '+%Y%m%d-%H%M%S')
echo "$now"
templatePath="tpl.xml"
cp $templatePath template.xml
id='Id'
sed -i -e "s/$id/$now/g" template.xml
echo "Version-id in template.xml is set to $now"
echo "--------------------"

# Determine build mode: default to production
ENV="${1:-prod}"
echo "Build environment: $ENV"

# Set base path
if [ "$ENV" = "dev" ]; then
  base_path="/ilias-luh/"
else
  base_path="/"
fi

echo "Using base path: $base_path"
echo "--------------------"

# Compile SCSS
echo "Remove old LUH-Style.css..."
rm -f LUH-Style/LUH-Style.css

echo "Compile with base path..."
# Create temporary SCSS wrapper to inject $base-path
wrapper_file="LUH-Style/scss/_temp_build.scss"
echo "\$base-path: \"$base_path\";" > $wrapper_file
echo "@use 'LUH-Style';" >> $wrapper_file

# Compile with Dart Sass
sass $wrapper_file LUH-Style/LUH-Style.css --no-source-map --style=compressed

# Clean up
rm -f $wrapper_file

echo "...done!"
echo "--------------------"
