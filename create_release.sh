#!/bin/bash

# Master script to increment version and generate release builds
# Usage: ./create_release.sh [patch|minor|major] [android|ios|both]
# Default: patch both

set -e  # Exit on any error

INCREMENT_TYPE=${1:-patch}
PLATFORM=${2:-both}

echo "🎯 OfficeLog Release Creator"
echo "================================"
echo "📈 Version increment: $INCREMENT_TYPE"
echo "📱 Platform: $PLATFORM"
echo ""

# Step 1: Increment version
echo "🔄 Step 1: Incrementing version..."
dart increment_version.dart $INCREMENT_TYPE

if [ $? -ne 0 ]; then
    echo "❌ Version increment failed!"
    exit 1
fi

echo ""

# Step 2: Generate release builds
echo "🔄 Step 2: Generating release builds..."
./generate_release.sh $PLATFORM

if [ $? -ne 0 ]; then
    echo "❌ Release build failed!"
    exit 1
fi

echo ""
echo "🎉 Release creation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   ✅ Version incremented ($INCREMENT_TYPE)"
echo "   ✅ Release builds generated ($PLATFORM)"
echo "   📁 Check the 'releases/' directory for your builds"
echo ""
echo "🚀 Ready for distribution!"
