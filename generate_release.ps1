# PowerShell script to generate release builds for Android and iOS
# Usage: .\generate_release.ps1 [android|ios|both]
# Default: both

param(
  [string]$Platform = "both"
)

$ErrorActionPreference = "Stop"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "🚀 Starting release build process..." -ForegroundColor Green
Write-Host "📅 Timestamp: $Timestamp" -ForegroundColor Cyan
Write-Host "🎯 Platform: $Platform" -ForegroundColor Yellow

# Function to build Android release
function Build-Android {
  Write-Host ""
  Write-Host "📱 Building Android release..." -ForegroundColor Blue
    
  # Clean previous builds
  Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
  flutter clean
    
  # Get dependencies
  Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
  flutter pub get
    
  # Build Android APK
  Write-Host "🔨 Building Android APK..." -ForegroundColor Yellow
  flutter build apk --release
    
  # Build Android App Bundle (AAB) for Play Store
  Write-Host "📦 Building Android App Bundle..." -ForegroundColor Yellow
  flutter build appbundle --release
    
  # Create release directory
  $releaseDir = "releases\android_$Timestamp"
  New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    
  # Copy APK
  Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "$releaseDir\"
    
  # Copy AAB
  Copy-Item "build\app\outputs\bundle\release\app-release.aab" "$releaseDir\"
    
  Write-Host "✅ Android build completed!" -ForegroundColor Green
  Write-Host "📁 APK: $releaseDir\app-release.apk" -ForegroundColor Cyan
  Write-Host "📁 AAB: $releaseDir\app-release.aab" -ForegroundColor Cyan
}

# Function to build iOS release
function Build-iOS {
  Write-Host ""
  Write-Host "🍎 Building iOS release..." -ForegroundColor Blue
    
  # Check if we're on macOS (PowerShell on macOS)
  if ($env:OS -ne "Windows_NT" -and $IsMacOS) {
    # Clean previous builds
    Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
    flutter clean
        
    # Get dependencies
    Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
    flutter pub get
        
    # Build iOS
    Write-Host "🔨 Building iOS..." -ForegroundColor Yellow
    flutter build ios --release --no-codesign
        
    # Create release directory
    $releaseDir = "releases\ios_$Timestamp"
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
        
    # Copy the built app
    Copy-Item -Recurse "build\ios\iphoneos\Runner.app" "$releaseDir\"
        
    Write-Host "✅ iOS build completed!" -ForegroundColor Green
    Write-Host "📁 App: $releaseDir\Runner.app" -ForegroundColor Cyan
    Write-Host "ℹ️  Note: iOS app needs to be signed and archived in Xcode for distribution" -ForegroundColor Yellow
  }
  else {
    Write-Host "⚠️  iOS builds can only be created on macOS" -ForegroundColor Red
    return $false
  }
}

# Main execution
switch ($Platform.ToLower()) {
  "android" {
    Build-Android
  }
  "ios" {
    Build-iOS
  }
  "both" {
    Build-Android
    if ($env:OS -ne "Windows_NT" -and $IsMacOS) {
      Build-iOS
    }
    else {
      Write-Host "⚠️  Skipping iOS build (not on macOS)" -ForegroundColor Yellow
    }
  }
  default {
    Write-Host "Error: Invalid platform. Use: android, ios, or both" -ForegroundColor Red
    exit 1
  }
}

Write-Host ""
Write-Host "🎉 Release build process completed!" -ForegroundColor Green
Write-Host "📊 Build summary:" -ForegroundColor Cyan
Write-Host "   - Platform: $Platform" -ForegroundColor White
Write-Host "   - Timestamp: $Timestamp" -ForegroundColor White
Write-Host "   - Output: releases\ directory" -ForegroundColor White
