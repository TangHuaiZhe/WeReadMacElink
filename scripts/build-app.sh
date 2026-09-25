#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/dist/WeReadMacElink.app"
contents_dir="$app_dir/Contents"

cd "$project_dir"
swift build -c release

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp ".build/release/WeReadMacElink" "$contents_dir/MacOS/WeReadMacElink"
cp "Resources/Info.plist" "$contents_dir/Info.plist"

codesign --force --sign - "$app_dir"
echo "$app_dir"
