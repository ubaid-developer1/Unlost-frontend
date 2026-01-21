# Firebase Storage Debugging Guide

## 🔍 How to Debug Firebase Storage Issues

### 1. **Test Firebase Connectivity**
- Tap the "Test Firebase" button on the home screen
- Check the debug console for connectivity test results
- This will verify if Firebase is working properly

### 2. **Check Debug Logs**
When adding items, look for these debug messages:

```
🔍 Save Item Debug:
  User: [user-id]
  Name: [item-name]
  Location: [location]
  Details: [details]
  Borrow Type: [borrow-type]
  Person: [person]
  Reminder Frequency: [frequency]
  Reminder Time: [time]
```

### 3. **Common Issues & Solutions**

#### **Issue: "No authenticated user found"**
**Symptoms**: Items not saving, authentication errors
**Solutions**:
- Log out and log back in
- Check if Firebase Auth is properly initialized
- Verify user is signed in before trying to save

#### **Issue: "Firebase connectivity test failed"**
**Symptoms**: Network errors, timeout errors
**Solutions**:
- Check internet connection
- Verify Firebase project configuration
- Check if Firebase rules allow read/write

#### **Issue: "Validation failed"**
**Symptoms**: Items not saving due to missing fields
**Solutions**:
- Fill all required fields (name, location, details)
- For borrowed/lent items: add person name, frequency, and time

### 4. **Firebase Console Check**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `unstop-c3b18`
3. Go to Firestore Database
4. Check if documents are being created under:
   ```
   users/[user-id]/items/[item-id]
   ```

### 5. **Debug Steps**

#### **Step 1: Test Connectivity**
```dart
// Run this test from the home screen
testFirebaseConnectivity()
```

#### **Step 2: Add Debug Logging**
The app now includes comprehensive debug logging:
- Item save attempts
- Firebase read/write operations
- Authentication status
- Validation results

#### **Step 3: Check Authentication**
```dart
// Verify user is authenticated
final user = FirebaseAuth.instance.currentUser;
print('User: ${user?.uid}');
```

#### **Step 4: Test Item Creation**
```dart
// Try creating a simple test item
final testItem = {
  'name': 'Test Item',
  'location': 'Test Location',
  'locationDetails': 'Test Details',
  'createdAt': FieldValue.serverTimestamp(),
};
```

### 6. **Firebase Rules Check**
Make sure your Firestore rules allow read/write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 7. **Troubleshooting Checklist**

- [ ] User is authenticated (check debug logs)
- [ ] Internet connection is working
- [ ] Firebase project is properly configured
- [ ] Firestore rules allow read/write
- [ ] All required fields are filled
- [ ] No validation errors in debug logs
- [ ] Firebase connectivity test passes

### 8. **Emergency Debug Mode**
If items are still not saving:

1. **Clear app data and reinstall**
2. **Log out and log back in**
3. **Check Firebase Console for any errors**
4. **Run the Firebase connectivity test**
5. **Try adding a simple test item**

### 9. **Contact Information**
If issues persist:
- Check Firebase Console for error logs
- Review debug console output
- Verify Firebase project settings
- Check network connectivity

## 🚨 Critical Debug Information

The app now logs all Firebase operations. Look for these patterns:

- `✅` = Success
- `❌` = Error
- `🔍` = Debug information
- `📝` = Data being saved
- `📊` = Query results

This will help identify exactly where the issue occurs in the Firebase storage process.



