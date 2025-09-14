# PowerShell master script to increment version and generate release builds
# Usage: .\create_release.ps1 [patch|minor|major] [android|ios|both]
# Default: patch both

param(
    [string]$IncrementType = "patch",
    [string]$Platform = "both"
)

$ErrorActionPreference = "Stop"

Write-Host "🎯 OfficeLog Release Creator" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "📈 Version increment: $IncrementType" -ForegroundColor Cyan
Write-Host "📱 Platform: $Platform" -ForegroundColor Cyan
Write-Host ""

# Step 1: Increment version
Write-Host "🔄 Step 1: Incrementing version..." -ForegroundColor Yellow
dart increment_version.dart $IncrementType

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Version increment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Generate release builds
Write-Host "🔄 Step 2: Generating release builds..." -ForegroundColor Yellow
.\generate_release.ps1 $Platform

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Release build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Release creation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "   ✅ Version incremented ($IncrementType)" -ForegroundColor White
Write-Host "   ✅ Release builds generated ($Platform)" -ForegroundColor White
Write-Host "   📁 Check the 'releases\' directory for your builds" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready for distribution!" -ForegroundColor Green
