# 🔒 Firebase Security Rules for Feedback

## Firestore Security Rules

Add these rules to your Firestore security rules to properly secure the feedback collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Existing attendance rules...
    match /attendance/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{year}/{month}/{day} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // User profiles
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Allow access to attendance subcollection
      match /attendance/{attendanceId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Offices collection (read-only for users, write for admins)
    match /offices/{officeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Holidays collection (read-only for users, write for admins)
    match /holidays/{holidayId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // 📝 FEEDBACK COLLECTION RULES
    match /feedback/{feedbackId} {
      // Allow authenticated users to create feedback
      allow create: if request.auth != null &&
        // Validate required fields
        request.resource.data.keys().hasAll(['message', 'timestamp']) &&
        // Ensure message is not empty
        request.resource.data.message is string &&
        request.resource.data.message.size() > 0 &&
        request.resource.data.message.size() <= 5000 &&
        // Validate timestamp is server timestamp
        request.resource.data.timestamp == request.time &&
        // Validate optional name field
        (!('name' in request.resource.data) ||
         (request.resource.data.name is string &&
          request.resource.data.name.size() <= 100)) &&
        // Validate optional email field
        (!('email' in request.resource.data) ||
         (request.resource.data.email is string &&
          request.resource.data.email.size() <= 254 &&
          request.resource.data.email.matches('.*@.*\\..*'))) &&
        // Ensure synced field is boolean
        request.resource.data.synced is bool;

      // Allow admins to read all feedback
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

      // Allow admins to delete feedback
      allow delete: if request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

      // Prevent updates to feedback (feedback should be immutable)
      allow update: if false;
    }
  }
}
```

## Rule Explanation

### Feedback Security Features

#### 1. **Create Rules**

-   ✅ Only authenticated users can submit feedback
-   ✅ Message field is required and must be 1-5000 characters
-   ✅ Timestamp must be server timestamp (prevents tampering)
-   ✅ Name is optional, max 100 characters
-   ✅ Email is optional, max 254 characters with basic format validation
-   ✅ Synced field must be boolean

#### 2. **Read Rules**

-   ✅ Only admins can read feedback
-   ✅ Users cannot read their own or others' feedback (privacy)
-   ✅ Prevents unauthorized access to feedback data

#### 3. **Delete Rules**

-   ✅ Only admins can delete feedback
-   ✅ Allows cleanup of inappropriate content
-   ✅ Maintains data integrity

#### 4. **Update Rules**

-   ❌ No updates allowed (feedback is immutable)
-   ✅ Prevents tampering with submitted feedback
-   ✅ Maintains audit trail integrity

### Data Validation

#### Required Fields

```javascript
// Message: 1-5000 characters
request.resource.data.message is string &&
request.resource.data.message.size() > 0 &&
request.resource.data.message.size() <= 5000

// Timestamp: Server timestamp only
request.resource.data.timestamp == request.time
```

#### Optional Fields

```javascript
// Name: Optional, max 100 characters
(!('name' in request.resource.data) ||
 (request.resource.data.name is string &&
  request.resource.data.name.size() <= 100))

// Email: Optional, basic format validation
(!('email' in request.resource.data) ||
 (request.resource.data.email is string &&
  request.resource.data.email.size() <= 254 &&
  request.resource.data.email.matches('.*@.*\\..*')))
```

### Admin Detection

```javascript
// Check if user exists and has admin role
exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
```

## 🔧 Setup Instructions

### 1. **Update Firestore Rules**

1. Go to Firebase Console
2. Navigate to Firestore Database → Rules
3. Add the feedback rules to your existing rules
4. Publish the updated rules

### 2. **Test the Rules**

```javascript
// Test feedback creation (should work)
{
  "message": "Great app!",
  "timestamp": "server_timestamp",
  "name": "John Doe",
  "email": "john@example.com",
  "synced": true
}

// Test invalid feedback (should fail)
{
  "message": "",  // Empty message - should fail
  "timestamp": "2025-01-01"  // Not server timestamp - should fail
}
```

### 3. **Admin User Setup**

Ensure admin users have the proper role in their user document:

```javascript
// users/{adminUserId}
{
  "name": "Admin User",
  "email": "admin@company.com",
  "role": "admin",  // Required for feedback access
  "createdAt": "timestamp",
  "officeId": "office_1"
}
```

## 🛡️ Security Benefits

### Data Protection

-   **Input Validation**: Prevents malicious or invalid data
-   **Size Limits**: Prevents spam and abuse
-   **Server Timestamps**: Prevents time manipulation
-   **Immutable Records**: Feedback cannot be modified after submission

### Privacy Protection

-   **User Isolation**: Users cannot read others' feedback
-   **Admin Only Access**: Only designated admins can view feedback
-   **Optional PII**: Name and email are optional fields

### System Integrity

-   **Authenticated Only**: Must be logged in to submit feedback
-   **Structured Data**: Enforces proper data format
-   **Audit Trail**: All feedback preserved with timestamps

These rules ensure your feedback system is secure, private, and maintains data integrity! 🔒✨
