#!/bin/bash

# Script to generate release builds for Android and iOS
# Usage: ./generate_release.sh [android|ios|both]
# Default: both

set -e  # Exit on any error

PLATFORM=${1:-both}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🚀 Starting release build process..."
echo "📅 Timestamp: $TIMESTAMP"
echo "🎯 Platform: $PLATFORM"

# Function to build Android release
build_android() {
    echo ""
    echo "📱 Building Android release..."
    
    # Clean previous builds
    echo "🧹 Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    echo "📦 Getting dependencies..."
    flutter pub get
    
    # Build Android APK
    echo "🔨 Building Android APK..."
    flutter build apk --release
    
    # Build Android App Bundle (AAB) for Play Store
    echo "📦 Building Android App Bundle..."
    flutter build appbundle --release
    
    # Create release directory
    mkdir -p "releases/android_$TIMESTAMP"
    
    # Copy APK
    cp build/app/outputs/flutter-apk/app-release.apk "releases/android_$TIMESTAMP/"
    
    # Copy AAB
    cp build/app/outputs/bundle/release/app-release.aab "releases/android_$TIMESTAMP/"
    
    echo "✅ Android build completed!"
    echo "📁 APK: releases/android_$TIMESTAMP/app-release.apk"
    echo "📁 AAB: releases/android_$TIMESTAMP/app-release.aab"
}

# Function to build iOS release
build_ios() {
    echo ""
    echo "🍎 Building iOS release..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  iOS builds can only be created on macOS"
        return 1
    fi
    
    # Clean previous builds
    echo "🧹 Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    echo "📦 Getting dependencies..."
    flutter pub get
    
    # Build iOS
    echo "🔨 Building iOS..."
    flutter build ios --release --no-codesign
    
    # Create release directory
    mkdir -p "releases/ios_$TIMESTAMP"
    
    # Copy the built app
    cp -r build/ios/iphoneos/Runner.app "releases/ios_$TIMESTAMP/"
    
    echo "✅ iOS build completed!"
    echo "📁 App: releases/ios_$TIMESTAMP/Runner.app"
    echo "ℹ️  Note: iOS app needs to be signed and archived in Xcode for distribution"
}

# Main execution
case $PLATFORM in
    "android")
        build_android
        ;;
    "ios")
        build_ios
        ;;
    "both")
        build_android
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_ios
        else
            echo "⚠️  Skipping iOS build (not on macOS)"
        fi
        ;;
    *)
        echo "Error: Invalid platform. Use: android, ios, or both"
        exit 1
        ;;
esac

echo ""
echo "🎉 Release build process completed!"
echo "📊 Build summary:"
echo "   - Platform: $PLATFORM"
echo "   - Timestamp: $TIMESTAMP"
echo "   - Output: releases/ directory"
