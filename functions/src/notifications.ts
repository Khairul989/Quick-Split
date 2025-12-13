import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  sendPushNotification,
  getPersonLinkedUserId,
  getGroupData,
  getSplitSessionData,
  getGroupMembers,
} from "./utils";

/**
 * Trigger: When a member is added to a group (via Firebase trigger)
 * Path: users/{userId}/groups/{groupId}/members/{personId} onCreate
 *
 * Action: Send FCM notification to the new member's linked user (if registered)
 * Payload: { type: 'group_invite', groupId, groupName, invitedBy }
 *
 * Note: This can be triggered manually via Cloud Function or automatically
 * when members are added to groups in Firestore
 */
export const onGroupMemberAdded = functions.firestore
  .document("users/{userId}/groups/{groupId}/members/{personId}")
  .onCreate(async (snap, context) => {
    const { userId, groupId, personId } = context.params;
    const memberData = snap.data();

    logger.info(`Group member added: userId=${userId}, groupId=${groupId}, personId=${personId}`);

    try {
      // Get the person's linked user ID (if they're a registered user)
      const linkedUserId = await getPersonLinkedUserId(userId, personId);

      if (!linkedUserId) {
        logger.info(
          `Person ${personId} is not linked to a registered user, skipping notification`
        );
        return;
      }

      // Get group data for the group name
      const groupData = await getGroupData(userId, groupId);
      if (!groupData) {
        logger.warn(`Group ${groupId} not found`);
        return;
      }

      const groupName = groupData.name || "A group";

      // Send notification to the new member
      await sendPushNotification(
        linkedUserId,
        {
          title: "Added to Group",
          body: `You've been added to ${groupName}`,
        },
        {
          type: "group_invite",
          groupId: groupId,
          groupName: groupName,
          invitedBy: userId,
        }
      );

      logger.info(
        `Sent group invite notification to ${linkedUserId} for group ${groupId}`
      );
    } catch (error) {
      logger.error("Error in onGroupMemberAdded:", error);
      // Don't re-throw - we want the function to be considered successful
      // even if notification fails
    }
  });

/**
 * Trigger: When a split session is created
 * Path: users/{userId}/splitSessions/{splitSessionId} onCreate
 *
 * Action: Send FCM notification to all participants who are registered users
 * Payload: { type: 'split_created', splitSessionId, groupId, totalAmount }
 *
 * Note: Only participants with linkedUserId will receive notifications
 */
export const onSplitSessionCreated = functions.firestore
  .document("users/{userId}/splitSessions/{splitSessionId}")
  .onCreate(async (snap, context) => {
    const { userId, splitSessionId } = context.params;
    const sessionData = snap.data();

    logger.info(
      `Split session created: userId=${userId}, splitSessionId=${splitSessionId}`
    );

    try {
      const groupId = sessionData.groupId as string | undefined;
      const participantPersonIds = sessionData.participantPersonIds as
        | string[]
        | undefined;
      const calculatedShares = sessionData.calculatedShares as
        | Array<Record<string, any>>
        | undefined;

      if (!participantPersonIds || participantPersonIds.length === 0) {
        logger.warn("No participants found in split session");
        return;
      }

      // Calculate total amount from calculated shares
      let totalAmount = 0;
      if (calculatedShares && calculatedShares.length > 0) {
        totalAmount = calculatedShares.reduce(
          (sum, share) => sum + (share.total || 0),
          0
        );
      }

      // Send notification to each participant who is a registered user
      const notificationPromises = participantPersonIds.map(async (personId) => {
        try {
          const linkedUserId = await getPersonLinkedUserId(userId, personId);

          if (!linkedUserId) {
            logger.debug(
              `Person ${personId} is not linked to a registered user`
            );
            return;
          }

          // Get the person's name for the notification
          const personName = (
            sessionData.calculatedShares as Array<Record<string, any>>
          )?.find((s) => s.personId === personId)?.personName || "A friend";

          await sendPushNotification(
            linkedUserId,
            {
              title: "Split Created",
              body: `You've been added to a split session for RM${totalAmount.toFixed(2)}`,
            },
            {
              type: "split_created",
              splitSessionId: splitSessionId,
              groupId: groupId || "",
              totalAmount: totalAmount.toFixed(2),
              personId: personId,
            }
          );

          logger.info(
            `Sent split created notification to ${linkedUserId} for session ${splitSessionId}`
          );
        } catch (error) {
          logger.warn(
            `Failed to send notification to person ${personId}:`,
            error
          );
          // Continue with other participants
        }
      });

      await Promise.all(notificationPromises);
      logger.info(
        `Completed sending split created notifications for session ${splitSessionId}`
      );
    } catch (error) {
      logger.error("Error in onSplitSessionCreated:", error);
      // Don't re-throw
    }
  });

/**
 * Trigger: When a group invite is accepted
 * Path: groupInvites/{inviteId} onUpdate (status: pending -> accepted)
 *
 * Action: Notify the group owner that someone joined
 * Payload: { type: 'invite_accepted', groupId, acceptedBy, acceptedByName }
 *
 * Note: Optional enhancement - implement if group invites are tracked in Firestore
 */
export const onGroupInviteAccepted = functions.firestore
  .document("groupInvites/{inviteId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed from pending to accepted
    const statusChanged =
      beforeData.status === "pending" && afterData.status === "accepted";

    if (!statusChanged) {
      return;
    }

    logger.info(`Group invite accepted: inviteId=${context.params.inviteId}`);

    try {
      const groupOwnerId = afterData.groupOwnerId as string;
      const groupId = afterData.groupId as string;
      const acceptedByUserId = afterData.acceptedByUserId as string;
      const acceptedByName = afterData.acceptedByName as string | undefined;

      // Send notification to group owner
      await sendPushNotification(
        groupOwnerId,
        {
          title: "Invite Accepted",
          body: `${acceptedByName || "Someone"} has joined your group`,
        },
        {
          type: "invite_accepted",
          groupId: groupId,
          acceptedBy: acceptedByUserId,
          acceptedByName: acceptedByName || "",
        }
      );

      logger.info(
        `Sent invite accepted notification to group owner ${groupOwnerId}`
      );
    } catch (error) {
      logger.error("Error in onGroupInviteAccepted:", error);
      // Don't re-throw
    }
  });

/**
 * HTTP callable function to manually trigger notifications
 * Useful for testing and manual scenarios
 *
 * Request body:
 * {
 *   "userId": "...",
 *   "type": "group_invite" | "split_created" | "invite_accepted",
 *   "data": { ...notification data }
 * }
 */
export const sendTestNotification = functions.https.onCall(
  async (data, context) => {
    // Verify the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId, type, data: notificationData } = data;

    if (!userId || !type || !notificationData) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: userId, type, data"
      );
    }

    try {
      logger.info(
        `Sending test notification to ${userId} of type ${type}`,
        notificationData
      );

      // Map type to title and body
      let title = "Notification";
      let body = "You have a new notification";

      switch (type) {
        case "group_invite":
          title = "Added to Group";
          body = `You've been added to ${notificationData.groupName || "a group"}`;
          break;
        case "split_created":
          title = "Split Created";
          body = `You've been added to a split session`;
          break;
        case "invite_accepted":
          title = "Invite Accepted";
          body = `${notificationData.acceptedByName || "Someone"} has joined your group`;
          break;
      }

      await sendPushNotification(userId, { title, body }, {
        type,
        ...notificationData,
      });

      return { success: true, message: "Test notification sent" };
    } catch (error) {
      logger.error("Error sending test notification:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send test notification"
      );
    }
  }
);
