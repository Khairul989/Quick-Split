import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export all Cloud Functions
export {
  onGroupMemberAdded,
  onSplitSessionCreated,
  onGroupInviteAccepted,
  sendTestNotification,
} from "./notifications";
