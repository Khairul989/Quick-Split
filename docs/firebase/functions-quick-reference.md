# Cloud Functions Quick Reference - QuickSplit

**Project:** quicksplit-ea021
**Runtime:** Node.js 18
**Region:** us-central1

---

## Quick Start

```bash
# 1. Install dependencies
cd functions && npm install

# 2. Compile TypeScript
npm run build

# 3. Test locally
cd .. && firebase emulators:start

# 4. Deploy to production
firebase deploy --only functions
```

---

## Common Commands

### Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onGroupMemberAdded

# Deploy multiple functions
firebase deploy --only functions:onGroupMemberAdded,functions:onSplitSessionCreated

# Force deploy (bypass cache)
firebase deploy --only functions --force
```

### Local Testing

```bash
# Start emulators
firebase emulators:start

# Start with imported data
firebase emulators:start --import ./emulator-data

# Export emulator data
firebase emulators:export ./emulator-data

# Start specific emulators only
firebase emulators:start --only functions,firestore
```

### Monitoring

```bash
# View all logs
firebase functions:log

# View specific function logs
firebase functions:log --only onGroupMemberAdded

# Follow logs in real-time
firebase functions:log --follow

# View last 100 lines
firebase functions:log --lines 100

# View logs from specific time
firebase functions:log --since 2h
```

### Function Management

```bash
# List all deployed functions
firebase functions:list

# Delete a function
firebase functions:delete onGroupMemberAdded

# Delete multiple functions
firebase functions:delete onGroupMemberAdded onSplitSessionCreated
```

### Project Management

```bash
# Login to Firebase
firebase login

# List projects
firebase projects:list

# Switch project
firebase use quicksplit-ea021

# View current project
firebase use
```

---

## Function URLs

### Production URLs

```
https://us-central1-quicksplit-ea021.cloudfunctions.net/onGroupMemberAdded
https://us-central1-quicksplit-ea021.cloudfunctions.net/onSplitSessionCreated
https://us-central1-quicksplit-ea021.cloudfunctions.net/onGroupInviteAccepted
https://us-central1-quicksplit-ea021.cloudfunctions.net/sendTestNotification
```

### Local URLs (Emulator)

```
http://localhost:5001/quicksplit-ea021/us-central1/sendTestNotification
```

---

## Test Notification

### Via HTTP Callable (Production)

```bash
curl -X POST https://us-central1-quicksplit-ea021.cloudfunctions.net/sendTestNotification \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "userId": "YOUR_FIREBASE_USER_ID"
    }
  }'
```

### Via HTTP Callable (Local)

```bash
curl -X POST http://localhost:5001/quicksplit-ea021/us-central1/sendTestNotification \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "userId": "testUserId"
    }
  }'
```

---

## Firestore Trigger Paths

| Function | Trigger Type | Path |
|----------|-------------|------|
| `onGroupMemberAdded` | onCreate | `users/{userId}/groups/{groupId}/members/{personId}` |
| `onSplitSessionCreated` | onCreate | `users/{userId}/splitSessions/{splitSessionId}` |
| `onGroupInviteAccepted` | onUpdate | `groupInvites/{inviteId}` |

---

## Notification Payload Structure

### Group Invite
```typescript
{
  type: 'group_invite',
  groupId: string,
  groupName: string,
  invitedBy: string
}
```

### Split Created
```typescript
{
  type: 'split_created',
  splitSessionId: string,
  groupId: string,
  merchantName: string,
  totalAmount: number
}
```

### Invite Accepted
```typescript
{
  type: 'invite_accepted',
  groupId: string,
  acceptedBy: string
}
```

---

## Troubleshooting

### Build fails
```bash
cd functions
npm run build  # Check for TypeScript errors
```

### Deploy fails
```bash
# Check you're logged in
firebase login

# Check project
firebase use

# Check billing
# Go to console.firebase.google.com → Upgrade to Blaze plan
```

### Function not triggering
```bash
# Check logs
firebase functions:log --only FUNCTION_NAME

# Verify Firestore path matches trigger path
# Verify document has linkedUserId field
```

### Timeout errors
```typescript
// In functions/src/notifications.ts, add:
export const onGroupMemberAdded = onDocumentCreated({
  document: 'users/{userId}/groups/{groupId}/members/{personId}',
  timeoutSeconds: 120,  // Increase timeout
}, async (event) => { /* ... */ });
```

---

## File Structure

```
functions/
├── src/
│   ├── index.ts              # Exports all functions
│   ├── notifications.ts      # Trigger implementations
│   └── utils.ts              # Helper functions
├── lib/                      # Compiled JavaScript (generated)
├── node_modules/             # Dependencies
├── package.json
├── tsconfig.json
└── README.md
```

---

## Development Workflow

1. **Make changes** to `src/*.ts`
2. **Compile** with `npm run build`
3. **Test locally** with `firebase emulators:start`
4. **Deploy** with `firebase deploy --only functions:FUNCTION_NAME`
5. **Monitor logs** with `firebase functions:log --follow`

---

## Cost Monitoring

```bash
# View usage in console
open https://console.firebase.google.com/project/quicksplit-ea021/usage

# Expected monthly cost (1000 users):
# - Invocations: ~10,000
# - Cost: $0 (within free tier)
```

---

## Security Rules (Firestore)

Functions need read/write access to Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Allow functions to read user profiles for FCM tokens
    match /users/{userId}/profile/data {
      allow read: if true;  // Functions can read
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## Links

- **Firebase Console:** https://console.firebase.google.com/project/quicksplit-ea021
- **Functions Dashboard:** https://console.firebase.google.com/project/quicksplit-ea021/functions
- **Usage & Billing:** https://console.firebase.google.com/project/quicksplit-ea021/usage
- **Logs Explorer:** https://console.cloud.google.com/logs/query?project=quicksplit-ea021

---

**Last Updated:** December 13, 2025
