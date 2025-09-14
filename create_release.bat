@echo off
REM Windows batch file to create releases
REM Usage: create_release.bat [patch|minor|major] [android|ios|both]
REM Default: patch both

set INCREMENT_TYPE=%1
if "%INCREMENT_TYPE%"=="" set INCREMENT_TYPE=patch

set PLATFORM=%2
if "%PLATFORM%"=="" set PLATFORM=both

echo 🎯 OfficeLog Release Creator
echo ================================
echo 📈 Version increment: %INCREMENT_TYPE%
echo 📱 Platform: %PLATFORM%
echo.

echo 🔄 Step 1: Incrementing version...
dart increment_version.dart %INCREMENT_TYPE%
if %ERRORLEVEL% neq 0 (
    echo ❌ Version increment failed!
    exit /b 1
)

echo.
echo 🔄 Step 2: Generating release builds...
powershell -ExecutionPolicy Bypass -File generate_release.ps1 %PLATFORM%
if %ERRORLEVEL% neq 0 (
    echo ❌ Release build failed!
    exit /b 1
)

echo.
echo 🎉 Release creation completed successfully!
echo.
echo 📋 Summary:
echo    ✅ Version incremented (%INCREMENT_TYPE%)
echo    ✅ Release builds generated (%PLATFORM%)
echo    📁 Check the 'releases\' directory for your builds
echo.
echo 🚀 Ready for distribution!
