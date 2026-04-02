#!/bin/bash
DERIVED_DATA="/tmp/NotchX-DerivedData"

xcodebuild -project ~/Desktop/Gaming/NotchX/NotchX.xcodeproj \
  -scheme NotchX \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  clean build \
&& {
    echo "→ Stopping existing instances..."
    pkill -x NotchX 2>/dev/null
    sleep 0.5
    echo "→ Launching NotchX..."
    open -n "$DERIVED_DATA/Build/Products/Debug/NotchX.app"
    sleep 1
    if pgrep -x NotchX > /dev/null; then
        echo "✓ NotchX is running."
        echo "  • Look for the ✦ sparkle icon in your menu bar (top right)."
        echo "  • Or hover over the MacBook notch (top center) to open the widget."
    else
        echo "✗ NotchX failed to launch. Check Console.app for crash logs."
        exit 1
    fi
}
