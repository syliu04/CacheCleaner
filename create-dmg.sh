#!/bin/bash

# Improved Cache Cleaner DMG Creation Script
# Creates a DMG with proper background and icon positioning

set -e

APP_NAME="CacheCleaner"
DMG_NAME="CacheCleaner-v1.0"
APP_PATH="./build/Build/Products/Release/${APP_NAME}.app"
VOLUME_NAME="Install Cache Cleaner"

echo "🚀 Creating professional DMG for Cache Cleaner..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please build the Release version first"
    exit 1
fi

# Clean up
echo "🧹 Cleaning up previous builds..."
rm -rf "${DMG_NAME}.dmg" "${DMG_NAME}-temp.dmg"
rm -rf .dmg-staging

# Create staging directory
echo "📁 Creating staging directory..."
mkdir -p .dmg-staging/.background

# Copy app
echo "📦 Copying app..."
cp -R "$APP_PATH" .dmg-staging/

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications .dmg-staging/Applications

# Create background image with Python
echo "🎨 Creating background image..."
python3 << 'PYTHON_SCRIPT'
from PIL import Image, ImageDraw, ImageFont

# Create image
width, height = 600, 400
img = Image.new('RGB', (width, height), color='#f0f0f0')
draw = ImageDraw.Draw(img)

# Try to use system font
try:
    font_large = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
    font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 16)
except:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Draw instruction text at bottom
text1 = "To install Cache Cleaner:"
text2 = "Drag the app icon to the Applications folder"
draw.text((width//2, height - 80), text1, fill='#333333', font=font_small, anchor='mm')
draw.text((width//2, height - 50), text2, fill='#333333', font=font_small, anchor='mm')

# Draw arrow
arrow_y = 180
arrow_start_x = 220
arrow_end_x = 380
arrow_color = '#007AFF'

# Arrow line
draw.line([(arrow_start_x, arrow_y), (arrow_end_x, arrow_y)], fill=arrow_color, width=4)

# Arrow head
arrow_head_size = 15
draw.polygon([
    (arrow_end_x, arrow_y),
    (arrow_end_x - arrow_head_size, arrow_y - arrow_head_size//2),
    (arrow_end_x - arrow_head_size, arrow_y + arrow_head_size//2)
], fill=arrow_color)

# Save
img.save('.dmg-staging/.background/background.png')
print("✅ Background created")
PYTHON_SCRIPT

# Create temporary DMG
echo "💾 Creating temporary DMG..."
hdiutil create -srcfolder .dmg-staging \
               -volname "${VOLUME_NAME}" \
               -fs HFS+ \
               -format UDRW \
               -size 250m \
               "${DMG_NAME}-temp.dmg"

# Mount it
echo "🔌 Mounting temporary DMG..."
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_NAME}-temp.dmg" | \
              grep -E '^/dev/' | tail -1 | awk '{$1=$2=""; print $0}' | xargs echo)

echo "📍 Mounted at: $MOUNT_POINT"
sleep 2

# Configure appearance with AppleScript
echo "🎨 Configuring DMG appearance..."
osascript <<END_SCRIPT
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set position of container window to {400, 100}

        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set text size of theViewOptions to 14

        -- Set background
        set background picture of theViewOptions to file ".background:background.png"

        -- Position icons
        set position of item "${APP_NAME}.app" to {150, 140}
        set position of item "Applications" to {450, 140}

        -- Force update
        close
        open
        update without registering applications
        delay 3
    end tell
end tell
END_SCRIPT

# Wait for Finder to finish
sleep 3

echo "💾 Saving .DS_Store..."
# Force sync
sync

# Unmount
echo "🔌 Unmounting..."
hdiutil detach "$MOUNT_POINT" -force || true
sleep 2

# Convert to final read-only DMG
echo "🗜️  Creating final compressed DMG..."
hdiutil convert "${DMG_NAME}-temp.dmg" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "${DMG_NAME}.dmg"

# Clean up
echo "🧹 Cleaning up..."
rm -rf .dmg-staging
rm -f "${DMG_NAME}-temp.dmg"

# Get size
DMG_SIZE=$(du -h "${DMG_NAME}.dmg" | cut -f1)

echo ""
echo "✅ DMG created successfully!"
echo "📦 File: ${DMG_NAME}.dmg"
echo "📏 Size: ${DMG_SIZE}"
echo ""
echo "The DMG now includes:"
echo "  ✓ Professional background with arrow"
echo "  ✓ Installation instructions"
echo "  ✓ Properly positioned icons"
echo "  ✓ Applications folder with system icon"
echo ""
echo "Test it: open ${DMG_NAME}.dmg"
