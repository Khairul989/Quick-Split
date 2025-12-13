# Firebase Cloud Functions Deployment Guide - QuickSplit

**Status:** Phase 7 Implementation
**Last Updated:** December 13, 2025
**Project:** QuickSplit (quicksplit-ea021)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Setup](#project-setup)
4. [Local Development & Testing](#local-development--testing)
5. [Deployment to Production](#deployment-to-production)
6. [Monitoring & Logs](#monitoring--logs)
7. [Troubleshooting](#troubleshooting)
8. [Cost Management](#cost-management)

---

## Overview

QuickSplit uses Firebase Cloud Functions to send real-time push notifications when:
- **New member added to group** → Notify the new member
- **Split session created** → Notify all participants
- **Group invite accepted** → Notify the group owner

### Functions Architecture

```
functions/
├── src/
│   ├── index.ts              # Main exports (entry point)
│   ├── notifications.ts      # Notification trigger functions
│   └── utils.ts              # Helper functions (sendPushNotification)
├── package.json
├── tsconfig.json
├── .gitignore
└── README.md
```

### Deployed Functions

| Function Name | Trigger Type | Firestore Path | Purpose |
|--------------|--------------|----------------|---------|
| `onGroupMemberAdded` | Firestore onCreate | `users/{userId}/groups/{groupId}/members/{personId}` | Notify new group member |
| `onSplitSessionCreated` | Firestore onCreate | `users/{userId}/splitSessions/{splitSessionId}` | Notify split participants |
| `onGroupInviteAccepted` | Firestore onUpdate | `groupInvites/{inviteId}` | Notify invite creator |
| `sendTestNotification` | HTTP Callable | N/A | Testing/development |

---

## Prerequisites

### Required Software

1. **Node.js 18+** (Cloud Functions requirement)
   ```bash
   node --version  # Should be 18.x or higher
   ```

   If not installed, download from [nodejs.org](https://nodejs.org/) or use [nvm](https://github.com/nvm-sh/nvm):
   ```bash
   nvm install 18
   nvm use 18
   ```

2. **Firebase CLI** (Latest version)
   ```bash
   npm install -g firebase-tools
   ```

   Verify installation:
   ```bash
   firebase --version
   ```

3. **Google Cloud Account**
   - Your Firebase project must be on the **Blaze (pay-as-you-go) plan**
   - Free tier is NOT sufficient for Cloud Functions deployment
   - See [Cloud Functions Pricing](#cost-management) for cost estimates

### Authentication

Login to Firebase CLI:
```bash
firebase login
```

This will open a browser window for authentication. Grant the necessary permissions.

Verify you're logged in:
```bash
firebase projects:list
```

You should see `quicksplit-ea021` in the list.

---

## Project Setup

### 1. Navigate to Functions Directory

```bash
cd /Volumes/KhaiSSD/Documents/Github/personal/quicksplit/functions
```

### 2. Install Dependencies

```bash
npm install
```

This installs all packages listed in `package.json`:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- TypeScript and type definitions

**Expected output:**
```
added 249 packages in 15s
```

### 3. Verify TypeScript Configuration

The `tsconfig.json` file should already be configured:
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

### 4. Compile TypeScript

```bash
npm run build
```

**Expected output:**
```
> build
> tsc
```

This compiles TypeScript files in `src/` to JavaScript in `lib/`.

**Verify compilation:**
```bash
ls lib/
# Should show: index.js, notifications.js, utils.js
```

---

## Local Development & Testing

### Start Firebase Emulators

Firebase Emulator Suite allows you to test functions locally without deploying.

**1. Start emulators from project root:**
```bash
cd /Volumes/KhaiSSD/Documents/Github/personal/quicksplit
firebase emulators:start
```

**2. Check output for URLs:**
```
┌─────────────────────────────────────────────────────────────┐
│ ✔  All emulators ready! It is now safe to connect your app. │
│ i  View Emulator UI at http://localhost:4000                │
└─────────────────────────────────────────────────────────────┘

┌────────────────┬────────────────┬─────────────────────────────────┐
│ Emulator       │ Host:Port      │ View in Emulator UI             │
├────────────────┼────────────────┼─────────────────────────────────┤
│ Functions      │ localhost:5001 │ http://localhost:4000/functions │
│ Firestore      │ localhost:8080 │ http://localhost:4000/firestore │
└────────────────┴────────────────┴─────────────────────────────────┘
```

**3. Open Emulator UI:**
```
http://localhost:4000
```

### Test Functions Locally

#### Option A: Test via Emulator UI

1. Go to **Firestore** tab in Emulator UI
2. Create a test document:
   - Collection: `users/testUserId/groups/testGroupId/members`
   - Document ID: `testPersonId`
   - Fields:
     ```json
     {
       "name": "John Doe",
       "emoji": "👤",
       "linkedUserId": "testLinkedUserId"
     }
     ```
3. Click **Add**
4. Go to **Logs** tab - you should see:
   ```
   onGroupMemberAdded triggered
   Sending notification to user: testLinkedUserId
   ```

#### Option B: Test via HTTP Callable

Call the `sendTestNotification` function:
```bash
curl -X POST http://localhost:5001/quicksplit-ea021/us-central1/sendTestNotification \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "userId": "YOUR_FIREBASE_USER_ID"
    }
  }'
```

**Expected response:**
```json
{
  "result": {
    "success": true,
    "message": "Test notification sent successfully"
  }
}
```

### Verify Function Behavior

**1. Check Firestore triggers:**
- Create a group member → Should trigger `onGroupMemberAdded`
- Create a split session → Should trigger `onSplitSessionCreated`
- Update invite status → Should trigger `onGroupInviteAccepted`

**2. Check notification payload:**
```typescript
// Expected payload structure
{
  type: 'group_invite' | 'split_created' | 'invite_accepted',
  groupId: string,
  groupName?: string,
  invitedBy?: string,
  splitSessionId?: string,
  merchantName?: string,
  totalAmount?: number
}
```

**3. Verify FCM token handling:**
- Functions should only send to users with `linkedUserId`
- Should handle missing FCM tokens gracefully
- Should remove invalid tokens automatically

---

## Deployment to Production

### Pre-Deployment Checklist

- [ ] Functions compile without errors (`npm run build`)
- [ ] Local emulator tests pass
- [ ] Firebase project is on **Blaze plan**
- [ ] You're logged into Firebase CLI
- [ ] Code is committed to Git (best practice)

### Deploy All Functions

**From project root:**
```bash
firebase deploy --only functions
```

**Expected output:**
```
=== Deploying to 'quicksplit-ea021'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: packaged functions (X KB) for uploading
✔  functions: functions folder uploaded successfully

The following functions will be deployed:

  onGroupMemberAdded(us-central1)
  onSplitSessionCreated(us-central1)
  onGroupInviteAccepted(us-central1)
  sendTestNotification(us-central1)

? Would you like to proceed with deployment? Yes

i  functions: updating Node.js 18 function onGroupMemberAdded(us-central1)...
i  functions: updating Node.js 18 function onSplitSessionCreated(us-central1)...
i  functions: updating Node.js 18 function onGroupInviteAccepted(us-central1)...
i  functions: updating Node.js 18 function sendTestNotification(us-central1)...
✔  functions[onGroupMemberAdded(us-central1)] Successful update operation.
✔  functions[onSplitSessionCreated(us-central1)] Successful update operation.
✔  functions[onGroupInviteAccepted(us-central1)] Successful update operation.
✔  functions[sendTestNotification(us-central1)] Successful update operation.

✔  Deploy complete!
```

### Deploy Specific Function

If you only want to deploy a single function (faster for development):
```bash
firebase deploy --only functions:onGroupMemberAdded
```

Or multiple specific functions:
```bash
firebase deploy --only functions:onGroupMemberAdded,functions:onSplitSessionCreated
```

### Deployment Time

- **First deployment:** 3-5 minutes (creating resources)
- **Subsequent deployments:** 1-2 minutes (updating existing functions)

### Verify Deployment

**1. List deployed functions:**
```bash
firebase functions:list
```

**Expected output:**
```
┌─────────────────────────────┬────────────┬───────┐
│ Name                        │ Region     │ State │
├─────────────────────────────┼────────────┼───────┤
│ onGroupMemberAdded          │ us-central1│ ACTIVE│
│ onSplitSessionCreated       │ us-central1│ ACTIVE│
│ onGroupInviteAccepted       │ us-central1│ ACTIVE│
│ sendTestNotification        │ us-central1│ ACTIVE│
└─────────────────────────────┴────────────┴───────┘
```

**2. Test production function:**
```bash
# Call sendTestNotification via production URL
curl -X POST https://us-central1-quicksplit-ea021.cloudfunctions.net/sendTestNotification \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "userId": "YOUR_REAL_FIREBASE_USER_ID"
    }
  }'
```

---

## Monitoring & Logs

### View Logs in Firebase Console

**Option 1: Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select `quicksplit-ea021` project
3. Navigate to **Build → Functions**
4. Click on a function name
5. Click **Logs** tab

**Option 2: Firebase CLI**
```bash
# View all function logs (real-time)
firebase functions:log

# View logs for specific function
firebase functions:log --only onGroupMemberAdded

# View last 100 lines
firebase functions:log --lines 100

# Follow logs in real-time
firebase functions:log --follow
```

### Log Levels

Functions use these log levels:
- `logger.info()` - General information
- `logger.warn()` - Warnings (e.g., missing FCM tokens)
- `logger.error()` - Errors (e.g., failed to send notification)
- `logger.debug()` - Debug information (disabled in production)

### Example Log Output

**Successful notification:**
```
2025-12-13 10:30:15.123 onGroupMemberAdded: New member added to group
2025-12-13 10:30:15.234 onGroupMemberAdded: Linked user ID: abc123
2025-12-13 10:30:15.345 sendPushNotification: Sending to 2 devices
2025-12-13 10:30:15.456 sendPushNotification: Notification sent successfully
```

**Failed notification (no FCM tokens):**
```
2025-12-13 10:30:15.123 onGroupMemberAdded: New member added to group
2025-12-13 10:30:15.234 onGroupMemberAdded: Linked user ID: abc123
2025-12-13 10:30:15.345 sendPushNotification: No FCM tokens found for user
```

### Google Cloud Logs Explorer

For advanced monitoring, use [Google Cloud Logs Explorer](https://console.cloud.google.com/logs):

1. Select `quicksplit-ea021` project
2. Use query:
   ```
   resource.type="cloud_function"
   resource.labels.function_name="onGroupMemberAdded"
   ```

---

## Troubleshooting

### Common Issues

#### 1. Deployment Fails - "Billing account not configured"

**Error:**
```
HTTP Error: 403, Firebase project must be on the Blaze (pay-as-you-go) plan
```

**Solution:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select `quicksplit-ea021`
3. Click **Upgrade** → Select **Blaze plan**
4. Add a billing account
5. Retry deployment

#### 2. TypeScript Compilation Errors

**Error:**
```
src/index.ts(10,5): error TS2322: Type 'string' is not assignable to type 'number'
```

**Solution:**
```bash
# Fix the TypeScript error in src/
npm run build  # Verify it compiles
firebase deploy --only functions
```

#### 3. Function Timeout

**Error:**
```
Function execution took 540000 ms, finished with status: 'timeout'
```

**Solution:**
Increase timeout in `src/notifications.ts`:
```typescript
export const onGroupMemberAdded = onDocumentCreated({
  document: 'users/{userId}/groups/{groupId}/members/{personId}',
  timeoutSeconds: 60,  // Add this (default is 60s, max 540s)
}, async (event) => {
  // ...
});
```

#### 4. Invalid FCM Token Errors

**Error in logs:**
```
Requested entity was not found. Invalid registration token
```

**Solution:**
This is handled automatically in `utils.ts`:
```typescript
// Invalid tokens are removed from user profile
if (error.code === 'messaging/invalid-registration-token') {
  await removeInvalidToken(userId, token);
}
```

No action needed - the function will clean up invalid tokens.

#### 5. Permission Denied Errors

**Error:**
```
Permission denied: Missing or insufficient permissions
```

**Solution:**
Update Firestore Security Rules:
```javascript
// In firebase console → Firestore → Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow Cloud Functions to write notifications
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Debug Checklist

When functions don't work as expected:

- [ ] Check function logs: `firebase functions:log`
- [ ] Verify Firestore document path matches trigger path
- [ ] Ensure user has FCM tokens in their profile
- [ ] Check that `linkedUserId` exists on Person documents
- [ ] Verify Firebase project billing is active
- [ ] Test with emulator first before deploying
- [ ] Check Firestore security rules allow function writes

---

## Cost Management

### Firebase Cloud Functions Pricing

**Free Tier (per month):**
- 2 million invocations
- 400,000 GB-seconds compute time
- 200,000 GHz-seconds compute time
- 5GB network egress

**QuickSplit Estimated Usage:**
- 1000 active users
- 10 notifications per user per month
- **Total: ~10,000 invocations/month**
- **Cost: $0** (well within free tier)

### Cost Optimization Tips

1. **Minimize function execution time**
   - Functions complete in ~100-200ms
   - Use async/await efficiently
   - Don't wait for unnecessary operations

2. **Batch notifications when possible**
   - Single Firestore query fetches all tokens
   - `sendMulticast()` sends to multiple devices in one call

3. **Clean up invalid tokens**
   - Reduces unnecessary FCM calls
   - Implemented in `utils.ts`

4. **Set memory limits appropriately**
   ```typescript
   export const onGroupMemberAdded = onDocumentCreated({
     document: 'users/{userId}/groups/{groupId}/members/{personId}',
     memory: '256MB',  // Default, sufficient for notifications
   }, async (event) => { /* ... */ });
   ```

5. **Monitor costs**
   - Check [Firebase Console → Usage and billing](https://console.firebase.google.com/project/quicksplit-ea021/usage)
   - Set up billing alerts in Google Cloud Console

### Projected Costs at Scale

| Users | Notifications/month | Invocations | Estimated Cost |
|-------|-------------------|-------------|----------------|
| 1,000 | 10,000 | 10,000 | $0 (free tier) |
| 10,000 | 100,000 | 100,000 | $0 (free tier) |
| 50,000 | 500,000 | 500,000 | ~$1-2/month |
| 100,000 | 1,000,000 | 1,000,000 | ~$3-5/month |

**Note:** FCM itself is free (unlimited notifications). Costs are only for Cloud Functions compute time.

---

## Additional Resources

### Firebase Documentation
- [Cloud Functions Get Started](https://firebase.google.com/docs/functions/get-started)
- [Cloud Functions Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)

### QuickSplit-Specific Docs
- `functions/README.md` - Quick reference guide
- `docs/PHASE7_IMPLEMENTATION.md` - Architecture details
- `docs/PHASE7_INTEGRATION_CHECKLIST.md` - Integration steps
- `PHASE7_README.md` - Phase 7 overview

### Useful Commands

```bash
# View project info
firebase projects:list
firebase use quicksplit-ea021

# Function management
firebase functions:list
firebase functions:log --only onGroupMemberAdded
firebase functions:delete onGroupMemberAdded

# Emulator
firebase emulators:start
firebase emulators:export ./emulator-data  # Save data
firebase emulators:start --import ./emulator-data  # Load data

# Deployment
firebase deploy --only functions
firebase deploy --only functions:onGroupMemberAdded
```

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section above
2. Review function logs: `firebase functions:log`
3. Check [Firebase Status Dashboard](https://status.firebase.google.com/)
4. Consult [Firebase Support](https://firebase.google.com/support)

---

**Last Updated:** December 13, 2025
**Maintained by:** QuickSplit Development Team
