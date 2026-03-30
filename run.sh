#!/bin/bash
DERIVED_DATA="/tmp/NotchX-DerivedData"
xcodebuild -project ~/Desktop/Gaming/NotchX/NotchX.xcodeproj \
  -scheme NotchX \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  clean build \
&& open "$DERIVED_DATA/Build/Products/Debug/NotchX.app"
