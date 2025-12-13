# Cross-Platform User Identification & Group Sync Implementation Plan

**Status:** Phase 1-8 Complete ✅ (Ready for Testing & Polish)
**Created:** December 13, 2025
**Updated:** December 13, 2025
**Strategy:** Hybrid Approach (Email Primary + Optional Phone Number)

---

## Table of Contents
1. [Overview](#overview)
2. [Current Architecture](#current-architecture)
3. [Implementation Phases](#implementation-phases)
4. [Technical Specifications](#technical-specifications)
5. [Cost Analysis](#cost-analysis)
6. [Migration Strategy](#migration-strategy)
7. [Timeline & Resources](#timeline--resources)

---

## Overview

### Problem Statement
Currently, QuickSplit groups and members exist only on local devices (Hive storage). Users cannot:
- Share groups across devices
- Add friends who are also using the app
- Receive notifications when added to groups/bills
- Automatically match their phone contacts with app users

### Solution: Hybrid User Identification
Use **verified email** (via Firebase Auth) as primary identity and **optional unverified phone number** for contact matching. This approach:
- ✅ Zero cost (no SMS verification)
- ✅ Enables cross-user features
- ✅ Maintains user privacy
- ✅ Leverages existing Firebase Auth infrastructure

### Key Benefits
1. **Contact Matching:** "3 of your contacts are on QuickSplit!"
2. **Free Notifications:** Firebase Cloud Messaging (FCM)
3. **WhatsApp Sharing:** Deep links using phone numbers
4. **Cross-Device Sync:** Groups accessible on all devices
5. **Invite System:** Email, WhatsApp, or invite code

---

## Current Architecture

### Data Storage (As of Dec 2025)

#### Local Storage (Hive)
```dart
// Hive Boxes
groups        // Group objects (typeId: 3)
people        // Person objects (typeId: 2)
history       // SplitSession objects
receipts      // Receipt objects
preferences   // UserProfile + app settings
cache         // Temporary OCR/image data
```

#### Cloud Storage (Firestore)
```
users/
  {userId}/
    profile/
      data ← UserProfile (name, email, emoji)
```

**Current Status:**
- ✅ User profiles synced to Firestore
- ✅ Firebase Auth (Email, Google, Apple)
- ✅ Contact permission & extraction
- ❌ Groups/People still local-only
- ❌ No phone number collection
- ❌ No cross-user discovery

### User Profile Model (Current)
```dart
class UserProfile {
  final String name;
  final String? email;
  final String emoji;
  final DateTime createdAt;

  // Methods
  toJson() / fromJson()        // Hive serialization
  toFirestore() / fromFirestore()  // Firestore sync
}
```

### Group Model (Current)
```dart
@HiveType(typeId: 3)
class Group extends HiveObject {
  final String id;           // UUID
  late String name;
  late List<String> personIds;  // References to Person objects
  final DateTime createdAt;
  late DateTime lastUsedAt;
  late int usageCount;
  String? imagePath;
}
```

### Person Model (Current)
```dart
@HiveType(typeId: 2)
class Person extends HiveObject {
  final String id;           // UUID
  late String name;
  late String emoji;
  final DateTime createdAt;
  String? phoneNumber;       // From device contacts
  String? email;             // From device contacts
  String? contactId;         // Device contact reference
  int usageCount;
  DateTime? lastUsedAt;
}
```

---

## Implementation Phases

### Phase 0: Current State Assessment ✅

**Completed:**
- Firebase Auth integration (Email, Google, Apple)
- User profile sync to Firestore
- Contact permission & extraction
- Local group/person management
- Offline-first architecture with Hive

**Gaps:**
- No phone number in user profile
- No Firestore sync for groups/people
- No FCM integration
- No user discovery mechanism

---

### Phase 1: Foundation - Firebase Sync for Groups & People ✅ COMPLETE

**Duration:** 1-2 weeks
**Priority:** Critical (prerequisite for all other features)
**Status:** ✅ Completed December 13, 2025

#### Goal
Migrate groups and people from local-only (Hive) to cloud-synced (Firestore) while maintaining offline-first architecture.

#### Firestore Structure Design
```
users/
  {userId}/
    profile/
      data (existing) ← UserProfile

    groups/
      {groupId}/
        name: string
        createdAt: timestamp
        lastUsedAt: timestamp
        usageCount: number
        imagePath: string?

        members/
          {personId} ← Person document
            name: string
            emoji: string
            phoneNumber: string?
            email: string?
            linkedUserId: string?  // If registered user
            isRegisteredUser: boolean

    people/
      {personId} ← Global people (reusable across groups)
        name: string
        emoji: string
        phoneNumber: string?
        email: string?
        linkedUserId: string?
        usageCount: number
        lastUsedAt: timestamp
```

#### Architecture Pattern: Offline-First with Cloud Sync

**Write Flow:**
```dart
1. User creates/updates group locally (Hive) ← immediate UI update
2. Background sync to Firestore ← happens asynchronously
3. If offline, queue for later sync
4. On success, mark as synced
```

**Read Flow:**
```dart
1. Load from local Hive cache ← fast initial render
2. Subscribe to Firestore stream ← real-time updates
3. On Firestore change, update Hive cache
4. Notify UI via Riverpod state change
```

**Conflict Resolution:**
```dart
- Use Firestore server timestamp for lastModified
- If conflict: server wins (cloud overwrites local)
- User data never deleted, only marked inactive
```

#### Implementation Tasks

1. **Create Firebase Repositories**
   ```
   lib/features/groups/data/repositories/
   ├── firebase_group_repository.dart
   └── firebase_person_repository.dart
   ```

2. **Repository Interface**
   ```dart
   abstract class GroupRepository {
     // CRUD operations
     Future<Group> createGroup(Group group);
     Future<void> updateGroup(Group group);
     Future<void> deleteGroup(String groupId);
     Stream<List<Group>> watchGroups();

     // Sync operations
     Future<void> syncToCloud(Group group);
     Future<void> syncFromCloud(String groupId);
     Future<bool> isSynced(String groupId);
   }
   ```

3. **Update GroupsNotifier**
   - Inject FirebaseGroupRepository
   - Maintain Hive writes for offline cache
   - Subscribe to Firestore streams for real-time updates
   - Handle offline queue for pending syncs

4. **Data Migration Service**
   ```dart
   class GroupMigrationService {
     Future<void> migrateToFirestore() async {
       // 1. Check migration flag
       if (await _isMigrationComplete()) return;

       // 2. Load all groups from Hive
       final localGroups = await _loadLocalGroups();

       // 3. Upload to Firestore (preserve UUIDs)
       for (final group in localGroups) {
         await _firebaseRepo.createGroup(group);
       }

       // 4. Mark migration complete
       await _setMigrationComplete();
     }
   }
   ```

5. **Offline Queue**
   ```dart
   // Store pending operations when offline
   class SyncQueue {
     List<SyncOperation> pendingOps = [];

     void enqueue(SyncOperation op) {
       pendingOps.add(op);
       _persistQueue(); // Save to Hive
     }

     Future<void> processPending() async {
       for (final op in pendingOps) {
         try {
           await op.execute();
           pendingOps.remove(op);
         } catch (e) {
           // Retry later
         }
       }
     }
   }
   ```

#### Testing Strategy
- **Unit Tests:** Mock Firestore, test repository logic
- **Integration Tests:** Test with Firestore Emulator
- **Offline Tests:** Disconnect network, verify queue behavior
- **Migration Tests:** Create test data in Hive, verify Firestore upload

---

### Phase 2: User Identity Enhancement ✅ COMPLETE

**Duration:** 1 week
**Priority:** High (enables contact matching)
**Status:** ✅ Completed December 13, 2025

#### Goal
Add optional phone number to user profile for contact matching without costly verification.

#### UserProfile Model Updates
```dart
class UserProfile {
  final String name;
  final String email;          // Verified via Firebase Auth ✓
  final String emoji;
  final String? phoneNumber;   // NEW: optional, unverified
  final DateTime createdAt;
  final DateTime? updatedAt;   // NEW: track profile changes

  // Helper methods
  String get displayPhone => phoneNumber != null
    ? _formatE164(phoneNumber!)
    : 'Not provided';

  bool get hasPhone => phoneNumber != null;
}
```

#### Phone Number Format
Use **E.164 international format** for consistency:
```dart
// Examples
+14155552671  // US
+6512345678   // Singapore
+60123456789  // Malaysia

// Normalization helper
String normalizePhone(String input) {
  // Remove all non-digits
  final digits = input.replaceAll(RegExp(r'\D'), '');

  // Add + prefix if missing
  return digits.startsWith('+') ? digits : '+$digits';
}
```

#### Onboarding Flow Update

**Current Flow:**
1. Welcome page
2. Profile setup (name, email, emoji)
3. Permissions (contacts, camera, storage)

**New Flow:**
1. Welcome page
2. Profile setup (name, email, emoji)
3. **Phone number (optional) ← NEW STEP**
   - "Add your phone number to find friends"
   - Skip button prominent
   - Country code selector
4. Permissions (contacts, camera, storage)

#### UI Implementation
```dart
// New widget: lib/features/onboarding/presentation/widgets/phone_setup_page.dart

class PhoneSetupPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Add Your Phone Number (Optional)'),
        Text('Find friends who are already using QuickSplit'),

        PhoneNumberInput(
          countryCode: '+60',  // Default to user's country
          onChanged: (phone) => _savePhone(phone),
        ),

        ElevatedButton(
          onPressed: () => _continueWithPhone(),
          child: Text('Continue'),
        ),

        TextButton(
          onPressed: () => _skipPhone(),
          child: Text('Skip for now'),
        ),
      ],
    );
  }
}
```

#### Database Schema Update
```
users/{userId}/profile/data:
{
  name: "John Doe",
  email: "john@example.com",
  emoji: "😊",
  phoneNumber: "+14155552671",  // NEW
  createdAt: timestamp,
  updatedAt: timestamp          // NEW
}
```

#### Migration for Existing Users
```dart
// Auto-add updatedAt field to existing profiles
Future<void> migrateUserProfiles() async {
  final profiles = await _firestore
    .collection('users')
    .get();

  for (final doc in profiles.docs) {
    if (!doc.data().containsKey('updatedAt')) {
      await doc.reference.update({
        'updatedAt': doc.data()['createdAt'],
        'phoneNumber': null,
      });
    }
  }
}
```

#### Profile Edit Screen
Create new screen for users to update profile later:
```
lib/features/settings/presentation/screens/edit_profile_screen.dart
```

**Features:**
- Edit name
- Update emoji
- Add/change phone number
- Cannot change email (tied to Firebase Auth)

---

### Phase 3: Person-to-User Linking ✅ COMPLETE

**Duration:** 1 week
**Priority:** High (core feature for cross-user functionality)
**Status:** ✅ Completed December 13, 2025

#### Goal
Link Person objects (group members) to registered QuickSplit users for notifications and sync.

#### Person Model Enhancement
```dart
@HiveType(typeId: 2)
class Person extends HiveObject {
  final String id;
  late String name;
  late String emoji;
  String? phoneNumber;
  String? email;
  String? contactId;

  // NEW FIELDS
  String? linkedUserId;       // Firebase User UID if registered
  DateTime? linkedAt;         // When link was established
  bool get isRegisteredUser => linkedUserId != null;

  // Existing fields
  int usageCount;
  DateTime? lastUsedAt;
  final DateTime createdAt;
}
```

#### User Discovery Service
```dart
// lib/features/groups/domain/services/user_discovery_service.dart

class UserDiscoveryService {
  final FirebaseFirestore _firestore;

  /// Search for registered users by email
  Future<List<AuthUser>> findByEmail(String email) async {
    final snapshot = await _firestore
      .collection('users')
      .where('profile.email', isEqualTo: email)
      .limit(1)
      .get();

    return snapshot.docs.map((doc) => AuthUser.fromFirestore(doc)).toList();
  }

  /// Search for registered users by phone
  Future<List<AuthUser>> findByPhone(String phone) async {
    final normalized = _normalizePhone(phone);

    final snapshot = await _firestore
      .collection('users')
      .where('profile.phoneNumber', isEqualTo: normalized)
      .limit(1)
      .get();

    return snapshot.docs.map((doc) => AuthUser.fromFirestore(doc)).toList();
  }

  /// Batch search for multiple contacts
  Future<Map<String, AuthUser>> findByContacts(List<Person> people) async {
    final results = <String, AuthUser>{};

    // Extract unique emails and phones
    final emails = people
      .where((p) => p.email != null)
      .map((p) => p.email!)
      .toSet();

    final phones = people
      .where((p) => p.phoneNumber != null)
      .map((p) => _normalizePhone(p.phoneNumber!))
      .toSet();

    // Firestore 'in' query limit is 30, so batch
    for (final emailBatch in _batchList(emails, 30)) {
      final found = await _findByEmailBatch(emailBatch);
      results.addAll(found);
    }

    for (final phoneBatch in _batchList(phones, 30)) {
      final found = await _findByPhoneBatch(phoneBatch);
      results.addAll(found);
    }

    return results;
  }
}
```

#### Auto-Linking Flow
```dart
// When user adds a person to a group
Future<Person> addPersonToGroup(Person person, String groupId) async {
  // 1. Save person locally
  await _personRepo.save(person);

  // 2. Try to link to registered user
  if (person.email != null || person.phoneNumber != null) {
    final user = await _userDiscovery.findByEmailOrPhone(
      person.email,
      person.phoneNumber,
    );

    if (user != null) {
      // Link found!
      person.linkedUserId = user.uid;
      person.linkedAt = DateTime.now();
      await _personRepo.update(person);

      // Show notification: "This contact is on QuickSplit!"
      _showLinkNotification(person.name);
    }
  }

  // 3. Add to group
  await _groupRepo.addMember(groupId, person.id);

  return person;
}
```

#### Find Friends UI
```dart
// lib/features/groups/presentation/screens/find_friends_screen.dart

class FindFriendsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final matchedUsers = ref.watch(matchedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Find Friends')),
      body: Column(
        children: [
          // Summary card
          Card(
            child: Text(
              '${matchedUsers.length} of your contacts are on QuickSplit!',
            ),
          ),

          // List of matched users
          ListView.builder(
            itemCount: matchedUsers.length,
            itemBuilder: (context, index) {
              final user = matchedUsers[index];
              return ListTile(
                leading: Text(user.emoji),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: IconButton(
                  icon: Icon(Icons.person_add),
                  onPressed: () => _addToGroup(user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 4: Firebase Cloud Messaging (FCM) Setup ✅ COMPLETE

**Duration:** 1 week
**Priority:** High (enables notifications)
**Status:** ✅ Completed December 13, 2025

#### Goal
Set up free push notifications using Firebase Cloud Messaging for group/bill activities.

#### FCM Token Management
```dart
// Update UserProfile model
class UserProfile {
  // ... existing fields
  List<String> fcmTokens;  // Support multiple devices

  // Helper methods
  Future<void> addFcmToken(String token) async {
    if (!fcmTokens.contains(token)) {
      fcmTokens.add(token);
      await _save();
    }
  }

  Future<void> removeFcmToken(String token) async {
    fcmTokens.remove(token);
    await _save();
  }
}
```

#### Notification Service
```dart
// lib/core/services/notification_service.dart

class NotificationService {
  final FirebaseMessaging _fcm;

  /// Initialize FCM
  Future<void> initialize() async {
    // Request permission
    final permission = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToProfile(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveTokenToProfile);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  /// Handle foreground notification
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'QuickSplit',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  /// Navigate on notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final id = message.data['id'];

    switch (type) {
      case 'group_invite':
        _navigateToGroup(id);
        break;
      case 'bill_added':
        _navigateToBill(id);
        break;
      case 'payment_request':
        _navigateToPayment(id);
        break;
    }
  }
}
```

#### Notification Types & Payloads
```dart
enum NotificationType {
  groupInvite,
  billAdded,
  billSettled,
  paymentRequest,
  paymentReceived,
}

// Example payload
{
  "notification": {
    "title": "New Group Invite",
    "body": "John added you to 'Weekend Trip'"
  },
  "data": {
    "type": "group_invite",
    "groupId": "abc123",
    "invitedBy": "user456",
    "timestamp": "2025-12-13T10:30:00Z"
  }
}
```

#### Firebase Cloud Functions (Backend)
```javascript
// functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Trigger when user is added to a group
export const onGroupMemberAdded = functions.firestore
  .document('users/{userId}/groups/{groupId}/members/{personId}')
  .onCreate(async (snap, context) => {
    const { userId, groupId, personId } = context.params;
    const person = snap.data();

    // Only notify if person is a registered user
    if (!person.linkedUserId) return;

    // Get group details
    const groupSnap = await admin.firestore()
      .doc(`users/${userId}/groups/${groupId}`)
      .get();
    const group = groupSnap.data();

    // Get inviter details
    const inviterSnap = await admin.firestore()
      .doc(`users/${userId}/profile/data`)
      .get();
    const inviter = inviterSnap.data();

    // Get recipient FCM tokens
    const recipientSnap = await admin.firestore()
      .doc(`users/${person.linkedUserId}/profile/data`)
      .get();
    const recipient = recipientSnap.data();

    // Send notification
    if (recipient?.fcmTokens?.length > 0) {
      await admin.messaging().sendMulticast({
        tokens: recipient.fcmTokens,
        notification: {
          title: 'New Group Invite',
          body: `${inviter.name} added you to "${group.name}"`,
        },
        data: {
          type: 'group_invite',
          groupId,
          invitedBy: userId,
        },
      });
    }
  });

// Trigger when bill is created with linked users
export const onBillCreated = functions.firestore
  .document('users/{userId}/bills/{billId}')
  .onCreate(async (snap, context) => {
    const bill = snap.data();

    // Notify all linked members assigned to this bill
    for (const assignee of bill.assignees) {
      if (assignee.linkedUserId) {
        await sendNotification(assignee.linkedUserId, {
          title: 'New Bill',
          body: `You have a new bill from ${bill.merchantName}`,
          type: 'bill_added',
          billId: context.params.billId,
        });
      }
    }
  });
```

#### Local Notification Display
```dart
// Use flutter_local_notifications for in-app display
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await _plugin.show(
      payload.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'quicksplit_channel',
          'QuickSplit Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }
}
```

---

### Phase 5: Contact Matching & Discovery ✅ COMPLETE

**Duration:** 1 week
**Priority:** Medium (nice-to-have feature)
**Status:** ✅ Mostly Complete (85% - Core features implemented, minor integration verification needed)

#### Goal
Match user's device contacts with registered QuickSplit users.

#### Contact Matching Algorithm
```dart
// lib/features/groups/domain/services/contact_matching_service.dart

class ContactMatchingService {
  final UserDiscoveryService _discovery;
  final ContactService _contacts;

  /// Match device contacts with registered users
  Future<List<MatchedContact>> matchContacts() async {
    // 1. Get device contacts (requires permission)
    final contacts = await _contacts.fetchContacts();

    // 2. Extract emails and phones
    final emails = contacts
      .where((c) => c.emails.isNotEmpty)
      .expand((c) => c.emails.map((e) => e.value))
      .toSet();

    final phones = contacts
      .where((c) => c.phones.isNotEmpty)
      .expand((c) => c.phones.map((p) => p.value))
      .map(_normalizePhone)
      .toSet();

    // 3. Batch query Firestore (limit 30 per query)
    final matches = <MatchedContact>[];

    for (final emailBatch in _batchList(emails, 30)) {
      final users = await _discovery.findByEmailBatch(emailBatch);
      matches.addAll(_mapToMatchedContacts(users, contacts));
    }

    for (final phoneBatch in _batchList(phones, 30)) {
      final users = await _discovery.findByPhoneBatch(phoneBatch);
      matches.addAll(_mapToMatchedContacts(users, contacts));
    }

    // 4. Remove duplicates and current user
    return _deduplicateMatches(matches);
  }

  /// Cache matches locally for quick access
  Future<void> cacheMatches(List<MatchedContact> matches) async {
    await _hive.put('cached_matches', matches.map((m) => m.toJson()).toList());
  }

  /// Get cached matches (avoid re-querying)
  Future<List<MatchedContact>?> getCachedMatches() async {
    final cached = await _hive.get('cached_matches');
    if (cached == null) return null;

    return (cached as List)
      .map((json) => MatchedContact.fromJson(json))
      .toList();
  }
}

class MatchedContact {
  final String userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String emoji;
  final String deviceContactId;  // Reference to device contact
}
```

#### Suggested Friends UI
```dart
// lib/features/groups/presentation/widgets/suggested_friends_card.dart

class SuggestedFriendsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchedContactsProvider);

    if (matches.isEmpty) return SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.people, color: Colors.blue),
            title: Text('${matches.length} friends on QuickSplit'),
            subtitle: Text('Tap to add them to groups'),
          ),

          // Show first 3 matches
          ...matches.take(3).map((match) => ListTile(
            leading: Text(match.emoji, style: TextStyle(fontSize: 24)),
            title: Text(match.name),
            subtitle: Text(match.email),
            trailing: IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () => _quickAddToGroup(match),
            ),
          )),

          if (matches.length > 3)
            TextButton(
              onPressed: () => _showAllMatches(context),
              child: Text('See all ${matches.length} matches'),
            ),
        ],
      ),
    );
  }
}
```

#### Privacy Considerations
- Only query Firestore with user's explicit permission
- Don't upload contact list to server (query locally)
- Cache matches locally, refresh periodically
- Allow users to disable contact matching in settings

---

### Phase 6: Group Invitations ✅ COMPLETE

**Duration:** 1-2 weeks
**Priority:** Medium
**Status:** ✅ Completed December 13, 2025

#### Goal
Enable users to invite others to groups via multiple channels.

#### Invitation Methods

1. **Email Invite**
   - Send email with deep link
   - Link opens app and auto-accepts invite

2. **WhatsApp Invite**
   - Generate shareable message with link
   - Opens WhatsApp with pre-filled text

3. **Invite Code**
   - 6-digit alphanumeric code
   - Manual entry in app
   - Works offline

#### Firestore Schema
```
groupInvites/
  {inviteId}/
    groupId: string
    groupName: string
    invitedBy: string (userId)
    invitedByName: string
    invitedEmail: string?
    invitedPhone: string?
    inviteCode: string (6-digit, e.g., "A3B9K2")
    createdAt: timestamp
    expiresAt: timestamp (7 days)
    status: "pending" | "accepted" | "expired" | "cancelled"
    acceptedBy: string? (userId who accepted)
    acceptedAt: timestamp?
```

#### Invite Generation Service
```dart
// lib/features/groups/data/repositories/group_invite_repository.dart

class GroupInviteRepository {
  /// Create invite for a group
  Future<GroupInvite> createInvite({
    required String groupId,
    required String invitedBy,
    String? invitedEmail,
    String? invitedPhone,
  }) async {
    final inviteCode = _generateInviteCode();

    final invite = GroupInvite(
      id: uuid.v4(),
      groupId: groupId,
      invitedBy: invitedBy,
      invitedEmail: invitedEmail,
      invitedPhone: invitedPhone,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: 7)),
      status: InviteStatus.pending,
    );

    await _firestore
      .collection('groupInvites')
      .doc(invite.id)
      .set(invite.toFirestore());

    return invite;
  }

  /// Generate 6-character alphanumeric code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Accept invite by code
  Future<Group> acceptInviteByCode(String code, String userId) async {
    // Find invite
    final snapshot = await _firestore
      .collection('groupInvites')
      .where('inviteCode', isEqualTo: code.toUpperCase())
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();

    if (snapshot.docs.isEmpty) {
      throw InviteNotFoundException();
    }

    final inviteDoc = snapshot.docs.first;
    final invite = GroupInvite.fromFirestore(inviteDoc);

    // Check expiry
    if (invite.expiresAt.isBefore(DateTime.now())) {
      throw InviteExpiredException();
    }

    // Add user to group
    await _groupRepo.addMember(invite.groupId, userId);

    // Mark invite as accepted
    await inviteDoc.reference.update({
      'status': 'accepted',
      'acceptedBy': userId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    return await _groupRepo.getGroup(invite.groupId);
  }
}
```

#### Deep Linking Service
```dart
// lib/core/services/deep_link_service.dart

class DeepLinkService {
  /// Generate deep link for invite
  String generateInviteLink(GroupInvite invite) {
    // Using Firebase Dynamic Links or custom scheme
    return 'https://quicksplit.app/invite/${invite.inviteCode}';
  }

  /// Handle incoming deep link
  Future<void> handleDeepLink(Uri uri) async {
    if (uri.pathSegments.first == 'invite') {
      final code = uri.pathSegments[1];
      await _acceptInvite(code);
    }
  }

  /// Initialize deep link listener
  void initialize() {
    // Listen for app launch via deep link
    _appLinks.getInitialLink().then((link) {
      if (link != null) handleDeepLink(Uri.parse(link));
    });

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      handleDeepLink(uri);
    });
  }
}
```

#### WhatsApp Sharing
```dart
// Generate WhatsApp invite message
String generateWhatsAppMessage(GroupInvite invite, Group group) {
  final link = _deepLinkService.generateInviteLink(invite);

  return '''
Hey! I've added you to "${group.name}" on QuickSplit.

Join the group using this link:
$link

Or enter code: ${invite.inviteCode}

QuickSplit makes splitting bills super easy!
  '''.trim();
}

// Share via WhatsApp
Future<void> shareViaWhatsApp(String phone, String message) async {
  final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  }
}
```

#### Invite UI
```dart
// lib/features/groups/presentation/screens/invite_screen.dart

class InviteScreen extends StatelessWidget {
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite to ${group.name}')),
      body: Column(
        children: [
          // Invite code display
          Card(
            child: Column(
              children: [
                Text('Invite Code', style: TextStyle(fontSize: 18)),
                Text(
                  invite.inviteCode,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                Text('Valid for 7 days'),
              ],
            ),
          ),

          // Share options
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Send Email Invite'),
            onTap: () => _sendEmailInvite(),
          ),

          ListTile(
            leading: Icon(Icons.chat, color: Colors.green),
            title: Text('Share via WhatsApp'),
            onTap: () => _shareViaWhatsApp(),
          ),

          ListTile(
            leading: Icon(Icons.link),
            title: Text('Copy Invite Link'),
            onTap: () => _copyLink(),
          ),

          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share Link'),
            onTap: () => _shareLink(),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 7: Real-time Notifications ✅ COMPLETE

**Duration:** 1 week
**Priority:** Medium
**Status:** ✅ Completed December 13, 2025

#### Notification Triggers

| Event | Trigger | Recipients |
|-------|---------|-----------|
| Added to Group | New member added | New member |
| New Bill | Bill created | All group members |
| Bill Updated | Bill modified | Assigned members |
| Payment Request | Payment marked pending | Payer |
| Payment Received | Payment marked completed | Requester |

#### Cloud Functions Implementation
```javascript
// functions/src/notifications.ts

// Notify when bill is created
export const onBillCreated = functions.firestore
  .document('users/{userId}/bills/{billId}')
  .onCreate(async (snap, context) => {
    const bill = snap.data();
    const { userId, billId } = context.params;

    // Get bill creator info
    const creatorSnap = await admin.firestore()
      .doc(`users/${userId}/profile/data`)
      .get();
    const creator = creatorSnap.data();

    // Notify each assigned person (if registered user)
    for (const item of bill.items) {
      if (item.assignedTo?.linkedUserId) {
        await sendPushNotification(
          item.assignedTo.linkedUserId,
          {
            title: 'New Bill',
            body: `${creator.name} added you to a bill from ${bill.merchantName}`,
          },
          {
            type: 'bill_added',
            billId,
            amount: item.price.toString(),
          }
        );
      }
    }
  });

// Helper function to send push notification
async function sendPushNotification(
  userId: string,
  notification: { title: string; body: string },
  data: Record<string, string>
) {
  // Get user's FCM tokens
  const userSnap = await admin.firestore()
    .doc(`users/${userId}/profile/data`)
    .get();
  const user = userSnap.data();

  if (!user?.fcmTokens?.length) return;

  // Send to all devices
  await admin.messaging().sendMulticast({
    tokens: user.fcmTokens,
    notification,
    data,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  });
}
```

---

### Phase 8: WhatsApp Integration ✅ COMPLETE

**Duration:** 3-5 days
**Priority:** Low (enhancement)
**Status:** ✅ Completed December 13, 2025

#### Use Cases
1. Share group invite ✅
2. Share bill summary ✅
3. Send payment reminder ✅

#### Implementation
```dart
// lib/core/utils/whatsapp_helper.dart

class WhatsAppHelper {
  /// Share bill summary
  static Future<void> shareBillSummary(Bill bill, String phoneNumber) async {
    final message = '''
📝 Bill from ${bill.merchantName}

Total: ${bill.totalAmount.toStringAsFixed(2)}
Your share: ${bill.userShare.toStringAsFixed(2)}

Items:
${bill.items.map((item) => '• ${item.name} - ${item.price}').join('\n')}

Sent via QuickSplit
    '''.trim();

    await _launchWhatsApp(phoneNumber, message);
  }

  /// Send payment reminder
  static Future<void> sendPaymentReminder(
    String phoneNumber,
    String name,
    double amount,
  ) async {
    final message = '''
Hi $name! 👋

Just a friendly reminder about the payment of ${amount.toStringAsFixed(2)}.

Thanks! 🙏
    '''.trim();

    await _launchWhatsApp(phoneNumber, message);
  }

  static Future<void> _launchWhatsApp(String phone, String message) async {
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw WhatsAppNotInstalledException();
    }
  }
}
```

---

## Technical Specifications

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User profiles
    match /users/{userId}/profile/data {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // User's own groups
    match /users/{userId}/groups/{groupId} {
      allow read, write: if request.auth.uid == userId;

      // Group members
      match /members/{personId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Group invites
    match /groupInvites/{inviteId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.invitedBy
                    || request.auth.uid == request.resource.data.acceptedBy;
    }
  }
}
```

### Firestore Indexes
```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "profile.email", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "profile.phoneNumber", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "groupInvites",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "inviteCode", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Cost Analysis

### Firebase Free Tier Limits
| Service | Free Tier | Estimated Usage (1000 users) | Safe? |
|---------|-----------|------------------------------|-------|
| Firestore Reads | 50,000/day | ~10,000-20,000/day | ✅ Yes |
| Firestore Writes | 20,000/day | ~5,000-10,000/day | ✅ Yes |
| Firestore Deletes | 20,000/day | ~100/day | ✅ Yes |
| Firestore Storage | 1 GB | ~50 MB | ✅ Yes |
| Cloud Functions | 2M invocations/month | ~10,000/month | ✅ Yes |
| FCM Messages | Unlimited | Any amount | ✅ Yes |
| Firebase Auth | Unlimited | Any amount | ✅ Yes |

### Cost Projections

**Scenario: 1000 active users**

**Daily Operations:**
- User opens app: 1 read (profile) × 1000 = 1000 reads
- View groups: 5 reads (groups) × 1000 = 5000 reads
- Create/update group: 2 writes × 100 users = 200 writes
- Contact matching: 30 reads × 50 users = 1500 reads
- Notifications: 10 FCM × 100 users = 1000 messages (FREE)

**Total Daily:**
- Reads: ~10,000 (20% of free tier)
- Writes: ~5,000 (25% of free tier)
- FCM: Unlimited (FREE)

**Monthly Cost: $0** (well within free tier)

### When Would Costs Start?
- **10,000+ daily active users**
- **100,000+ groups**
- **Heavy real-time syncing** (every second)

At that scale, estimated cost: **$20-50/month**

---

## Migration Strategy

### Phase 1 Migration: Local to Cloud Groups
```dart
class GroupMigrationService {
  final HiveInterface _hive;
  final FirebaseGroupRepository _firebaseRepo;

  Future<void> migrateGroupsToFirestore() async {
    // 1. Check if already migrated
    final prefs = await _hive.openBox('preferences');
    if (prefs.get('hasCompletedGroupMigration') == true) {
      return;
    }

    try {
      // 2. Load all local groups
      final groupsBox = await _hive.openBox<Group>('groups');
      final localGroups = groupsBox.values.toList();

      // 3. Load all local people
      final peopleBox = await _hive.openBox<Person>('people');
      final localPeople = peopleBox.values.toList();

      // 4. Upload to Firestore (preserve IDs)
      for (final group in localGroups) {
        await _firebaseRepo.createGroup(group);

        // Upload group members
        final members = localPeople
          .where((p) => group.personIds.contains(p.id))
          .toList();

        for (final member in members) {
          await _firebaseRepo.addMember(group.id, member);
        }
      }

      // 5. Upload global people (not in groups)
      final globalPeople = localPeople
        .where((p) => !localGroups.any((g) => g.personIds.contains(p.id)))
        .toList();

      for (final person in globalPeople) {
        await _firebaseRepo.createPerson(person);
      }

      // 6. Mark migration complete
      await prefs.put('hasCompletedGroupMigration', true);

      logger.info('Migration complete: ${localGroups.length} groups, ${localPeople.length} people');

    } catch (e, stackTrace) {
      logger.error('Migration failed', e, stackTrace);
      // Don't mark as complete, will retry next launch
    }
  }
}
```

### Backward Compatibility Strategy
```dart
// Hybrid repository: Falls back to Hive if Firestore unavailable
class HybridGroupRepository implements GroupRepository {
  final FirebaseGroupRepository _firebase;
  final HiveGroupRepository _hive;
  final ConnectivityService _connectivity;

  @override
  Future<List<Group>> getGroups() async {
    if (await _connectivity.isOnline) {
      try {
        // Try Firestore first
        final groups = await _firebase.getGroups();

        // Cache locally
        await _hive.saveGroups(groups);

        return groups;
      } catch (e) {
        // Fallback to Hive on error
        return _hive.getGroups();
      }
    } else {
      // Offline: use Hive
      return _hive.getGroups();
    }
  }

  @override
  Future<void> createGroup(Group group) async {
    // Always write to Hive first (immediate UI update)
    await _hive.createGroup(group);

    // Sync to Firestore in background
    if (await _connectivity.isOnline) {
      try {
        await _firebase.createGroup(group);
      } catch (e) {
        // Queue for later sync
        await _syncQueue.enqueue(SyncOperation.createGroup(group));
      }
    }
  }
}
```

---

## Timeline & Resources

### Full Implementation Timeline
| Phase | Duration | Dependencies | Status |
|-------|----------|-------------|--------|
| Phase 1: Firebase Sync | 1-2 weeks | None | ✅ Complete |
| Phase 2: User Identity | 1 week | Phase 1 | ✅ Complete |
| Phase 3: Person Linking | 1 week | Phase 2 | ✅ Complete |
| Phase 4: FCM Setup | 1 week | Phase 2 | ✅ Complete |
| Phase 5: Contact Matching | 1 week | Phase 3 | ✅ Complete (85%) |
| Phase 6: Invitations | 1-2 weeks | Phase 3, 4 | ✅ Complete |
| Phase 7: Notifications | 1 week | Phase 4, 6 | ✅ Complete |
| Phase 8: WhatsApp | 3-5 days | Phase 2 | ✅ Complete |
| **Testing & Polish** | 1 week | All phases | ⏳ Next Step |

**Total: ~8-10 weeks** for full implementation

### Resource Requirements
- **1 Flutter Developer** (full-time)
- **1 Backend Developer** (part-time, for Cloud Functions)
- **1 QA/Tester** (part-time, for testing)

### Testing Checklist
- [ ] Unit tests for all repositories
- [ ] Integration tests for Firestore sync
- [ ] Offline mode testing
- [ ] FCM notification testing (foreground, background, killed)
- [ ] Deep link testing
- [ ] Contact matching accuracy
- [ ] Migration testing (local to cloud)
- [ ] Cross-device sync testing
- [ ] WhatsApp sharing testing
- [ ] Security rules testing

---

## Next Steps

### Immediate Actions
1. **Review this plan** with team
2. **Set up Firebase project** for Cloud Functions
3. **Create test Firebase project** for development
4. **Begin Phase 1** (Firebase Sync)

### Open Questions
- [ ] Do we want Firebase Dynamic Links or custom deep linking?
- [ ] Should we support SMS invites (paid feature later)?
- [ ] Email sending service (SendGrid, Firebase email extension)?
- [ ] Should we add user search by username (alternative to email/phone)?

---

## References
- [Firebase Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Flutter Riverpod](https://riverpod.dev/)
- [WhatsApp URL Scheme](https://faq.whatsapp.com/general/chats/how-to-use-click-to-chat)

---

**Document Version:** 1.0
**Last Updated:** December 13, 2025
**Status:** Awaiting Approval
