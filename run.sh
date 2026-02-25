#!/bin/bash
xcodebuild -project ~/Desktop/Gaming/NotchX/NotchX.xcodeproj -scheme NotchX -configuration Debug clean build && open ~/Library/Developer/Xcode/DerivedData/NotchX-*/Build/Products/Debug/NotchX.app
