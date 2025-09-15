# OfficeLog v1.2.1 Release Notes

**Release Date:** September 16, 2025  
**Version:** 1.2.1+3

## 🎉 What's New

### 🔧 **Major Bug Fixes**
- **Fixed Login Issues**: Resolved SummaryScreen crash that occurred immediately after successful login
- **Authentication Flow**: Login now works properly - users can sign in and accounts are created in Firebase
- **Settings Buttons**: Fixed "Open Settings" button functionality with correct package name references

### 📊 **3-Day Weekly Rule Consistency**
- **Unified Calculation**: All percentage calculations now consistently use the 3-day weekly compliance rule
- **Summary Screen**: Fixed AttendanceService.getMonthDetails() to use proper compliance calculation
- **Accurate Reporting**: Overall attendance, quarterly stats, and monthly breakdowns all use the same logic

### ⚙️ **Enhanced Settings Experience**
- **Refresh Button**: Service status refresh now works with loading spinner and visual feedback
- **Permission Status**: Improved display of location permission status with detailed descriptions
- **Dark Mode**: Fixed visibility issues with permission containers and text in dark mode
- **Direct Access**: Added "Open Permission Settings" button for easy access to app permissions

### 🎨 **UI/UX Improvements**
- **Loading States**: Added proper loading indicators for async operations
- **Error Handling**: Better error messages and user feedback throughout the app
- **Visual Feedback**: Timestamps show when service status was last refreshed
- **Theme Support**: All new UI elements properly support both light and dark themes

## 🔧 **Technical Details**

### **Files Modified:**
- `lib/screens/summary_screen.dart` - Fixed null pointer crash and improved quarterly stats
- `lib/services/attendance_service.dart` - Implemented 3-day rule in getMonthDetails()
- `lib/screens/settings_screen.dart` - Enhanced refresh button and permission status
- `lib/services/battery_optimization_service.dart` - Fixed package name references

### **Version Information:**
- **Semantic Version:** 1.2.1
- **Build Number:** 10201 (auto-calculated: 1×10000 + 2×100 + 1)
- **Gradle Version Code:** 3

## 🚀 **Installation**

### **For Google Play Store:**
- Use `OfficeLog-v1.2.1.aab`

### **For Direct Installation:**
- Use `OfficeLog-v1.2.1.apk`

## 📱 **Compatibility**
- **Android:** API 21+ (Android 5.0+)
- **Firebase:** Fully configured and tested
- **Permissions:** Location, Notifications, Background activity

## 🔒 **Security & Privacy**
- All location data remains local and secure
- Firebase authentication working properly
- No data collection or third-party sharing

---

**Previous Version:** v1.2.0  
**Upgrade Path:** Direct upgrade from any previous version
