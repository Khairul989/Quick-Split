# Firebase Cloud Functions for QuickSplit

This directory contains Firebase Cloud Functions that handle real-time push notifications for the QuickSplit app.

## Features

- **Push Notifications**: Send FCM messages to app users based on Firestore events
- **Event Triggers**: Automatically triggered by Firestore document changes
- **User Linking**: Notifies registered app users about group and split events
- **Error Handling**: Gracefully handles missing tokens and user data
- **Testing**: Callable function for manual notification testing

## Cloud Functions

### 1. `onGroupMemberAdded`

**Trigger**: Firestore `onCreate` on `users/{userId}/groups/{groupId}/members/{personId}`

**When**: A new member is added to a group

**Action**: Sends notification to the member's linked user (if registered)

**Notification Payload**:
```json
{
  "type": "group_invite",
  "groupId": "...",
  "groupName": "...",
  "invitedBy": "..."
}
```

### 2. `onSplitSessionCreated`

**Trigger**: Firestore `onCreate` on `users/{userId}/splitSessions/{splitSessionId}`

**When**: A new split session is created

**Action**: Sends notification to all participants who are registered users

**Notification Payload**:
```json
{
  "type": "split_created",
  "splitSessionId": "...",
  "groupId": "...",
  "totalAmount": "..."
}
```

### 3. `onGroupInviteAccepted`

**Trigger**: Firestore `onUpdate` on `groupInvites/{inviteId}`

**When**: A group invite is accepted (status changes from `pending` to `accepted`)

**Action**: Notifies the group owner that someone joined

**Notification Payload**:
```json
{
  "type": "invite_accepted",
  "groupId": "...",
  "acceptedBy": "...",
  "acceptedByName": "..."
}
```

### 4. `sendTestNotification` (Callable)

**Type**: HTTP Callable Function

**Purpose**: Manually send test notifications for development/testing

**Request**:
```dart
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('sendTestNotification');

final result = await callable.call({
  'userId': 'target-user-id',
  'type': 'group_invite',
  'data': {
    'groupId': 'test-group',
    'groupName': 'Test Group',
    'invitedBy': 'inviter-user-id',
  },
});
```

## Prerequisites

- Node.js 18+ installed
- Firebase CLI installed: `npm install -g firebase-tools`
- Authentication: `firebase login`
- Firebase project configured

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Select Firebase Project

```bash
firebase use quicksplit-ea021
# or
firebase use --add
```

### 3. Build TypeScript

```bash
npm run build
```

## Local Development

### Run Emulator

```bash
npm start
# or
npm run serve
```

The emulator will start local Firebase emulators for Firestore, Auth, and Functions.

### Access Emulator UI

Open http://localhost:4000 to access the Firebase Emulator Suite UI

## Deployment

### Deploy All Functions

```bash
firebase deploy --only functions
```

### Deploy Specific Function

```bash
firebase deploy --only functions:onGroupMemberAdded
firebase deploy --only functions:onSplitSessionCreated
firebase deploy --only functions:onGroupInviteAccepted
firebase deploy --only functions:sendTestNotification
```

### Check Deployment Status

```bash
firebase functions:list
```

## Monitoring

### View Logs

```bash
firebase functions:log
# or with filter
firebase functions:log --limit 50
```

### View Specific Function Logs

```bash
firebase functions:log --function onGroupMemberAdded
```

### Firebase Console

View detailed logs and metrics in [Firebase Console](https://console.firebase.google.com/project/quicksplit-ea021/functions)

## Testing

### Test Notifications Locally

1. Start the emulator:
   ```bash
   npm start
   ```

2. Use the Emulator UI or a tool like `curl` or Postman to call the function:
   ```bash
   curl -X POST http://localhost:5001/quicksplit-ea021/us-central1/sendTestNotification \
     -H "Content-Type: application/json" \
     -d '{
       "data": {
         "userId": "test-user-123",
         "type": "group_invite",
         "data": {
           "groupId": "group-1",
           "groupName": "Test Group",
           "invitedBy": "user-1"
         }
       }
     }'
   ```

### Test from Flutter App

Use the `sendTestNotification` callable function from the app:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> testNotification() async {
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('sendTestNotification');

  try {
    final result = await callable.call({
      'userId': 'your-user-id',
      'type': 'group_invite',
      'data': {
        'groupId': 'test-group',
        'groupName': 'Test Group',
        'invitedBy': 'inviter-id',
      },
    });
    print('Notification sent: ${result.data}');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Firestore Structure

The Cloud Functions expect the following Firestore structure:

```
users/{userId}/
  ├── profile (UserProfile)
  │   └── fcmTokens: string[]
  │   └── name: string
  │   └── phoneNumber: string
  ├── groups/{groupId}/
  │   ├── name: string
  │   ├── personIds: string[]
  │   └── members/{personId}/
  │       ├── name: string
  │       ├── linkedUserId: string (optional)
  │       └── ...
  ├── splitSessions/{splitSessionId}/
  │   ├── groupId: string
  │   ├── participantPersonIds: string[]
  │   └── calculatedShares: PersonShare[]
  └── people/{personId}/
      ├── name: string
      └── linkedUserId: string (optional)
```

## Important Notes

1. **FCM Tokens**: The functions read FCM tokens from `users/{userId}.fcmTokens` array
2. **User Linking**: Only people with `linkedUserId` field will receive notifications
3. **Error Handling**: Functions continue gracefully if notification fails (e.g., invalid tokens)
4. **Invalid Tokens**: Automatically removed from user profile if delivery fails
5. **Async Operation**: Notifications are sent asynchronously - functions complete quickly

## Troubleshooting

### No Notifications Received

1. Check FCM token is saved in user profile:
   ```bash
   firebase firestore --project=quicksplit-ea021
   # Query: users > your-user-id > fcmTokens
   ```

2. Verify function logs:
   ```bash
   firebase functions:log --function onSplitSessionCreated
   ```

3. Check notification service is properly initialized in app

### Function Timeout

- Cloud Functions default timeout is 60 seconds
- Check if Firestore queries are slow
- Optimize database indexes if needed

### Permission Denied

- Ensure Service Account has required permissions in Firebase Console
- Check Firestore security rules allow function access

## File Structure

```
functions/
├── src/
│   ├── index.ts              # Main entry point, exports all functions
│   ├── notifications.ts      # Notification trigger implementations
│   └── utils.ts              # Helper functions for Firestore queries
├── lib/                       # Compiled JavaScript (auto-generated)
├── package.json              # Node dependencies
├── tsconfig.json             # TypeScript configuration
├── .gitignore                # Git ignore rules
└── README.md                 # This file
```

## Environment Variables

No environment variables required. All configuration comes from Firebase Console.

Optional: Create `.env` for local secrets:
```env
FIREBASE_PROJECT_ID=quicksplit-ea021
FIREBASE_DATABASE_URL=...
```

## Contributing

When adding new Cloud Functions:

1. Add function in `notifications.ts`
2. Export in `index.ts`
3. Add corresponding notification type in app
4. Document the trigger and payload in this README
5. Test locally before deploying

## Related Documentation

- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Cloud Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [QuickSplit NotificationService](../lib/core/services/notification_service.dart)
