import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Send a push notification to a user via their FCM tokens
 * @param userId - Firebase user ID
 * @param notification - Notification title and body
 * @param data - Custom data payload to send with notification
 * @returns Promise that resolves when notification is sent
 */
export async function sendPushNotification(
  userId: string,
  notification: {
    title: string;
    body: string;
  },
  data: Record<string, string>
): Promise<void> {
  try {
    // Get user's FCM tokens from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      logger.warn(`User document not found for userId: ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const fcmTokens: string[] = userData?.fcmTokens || [];

    if (fcmTokens.length === 0) {
      logger.info(`No FCM tokens found for userId: ${userId}`);
      return;
    }

    // Build multicast message
    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data,
      tokens: fcmTokens,
    };

    // Send multicast message
    const response = await admin.messaging().sendMulticast(message);

    logger.info(
      `Sent notification to userId: ${userId}, successCount: ${response.successCount}, failureCount: ${response.failureCount}`
    );

    // Handle failures - remove invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(fcmTokens[idx]);
          logger.warn(
            `Failed to send to token ${fcmTokens[idx]}: ${resp.error?.message}`
          );
        }
      });

      // Remove invalid tokens from user document
      if (failedTokens.length > 0) {
        const validTokens = fcmTokens.filter(
          (token) => !failedTokens.includes(token)
        );
        await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .update({
            fcmTokens: validTokens,
          });

        logger.info(
          `Removed ${failedTokens.length} invalid tokens for userId: ${userId}`
        );
      }
    }
  } catch (error) {
    logger.error(`Error sending push notification to userId: ${userId}:`, error);
    // Don't re-throw - we want Cloud Function to succeed even if notification fails
  }
}

/**
 * Get a user's document from Firestore by phone number
 * Used for user discovery and linking
 * @param phoneNumber - User's phone number
 * @returns User document ID if found, null otherwise
 */
export async function findUserByPhoneNumber(
  phoneNumber: string
): Promise<string | null> {
  try {
    const snapshot = await admin
      .firestore()
      .collection("users")
      .where("phoneNumber", "==", phoneNumber)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    return snapshot.docs[0].id;
  } catch (error) {
    logger.error(`Error finding user by phone number:`, error);
    return null;
  }
}

/**
 * Get a person's linked user ID
 * Used to find the Firebase user associated with a Person
 * @param userId - The owner user ID
 * @param personId - The person ID
 * @returns Linked user ID if found, null otherwise
 */
export async function getPersonLinkedUserId(
  userId: string,
  personId: string
): Promise<string | null> {
  try {
    const personDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("people")
      .doc(personId)
      .get();

    if (!personDoc.exists) {
      return null;
    }

    const personData = personDoc.data();
    return personData?.linkedUserId || null;
  } catch (error) {
    logger.error(
      `Error getting linked user ID for person ${personId}:`,
      error
    );
    return null;
  }
}

/**
 * Get a group's data by ID
 * @param userId - The owner user ID
 * @param groupId - The group ID
 * @returns Group data if found, null otherwise
 */
export async function getGroupData(
  userId: string,
  groupId: string
): Promise<Record<string, any> | null> {
  try {
    const groupDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("groups")
      .doc(groupId)
      .get();

    if (!groupDoc.exists) {
      return null;
    }

    return groupDoc.data() || null;
  } catch (error) {
    logger.error(`Error getting group data for groupId: ${groupId}:`, error);
    return null;
  }
}

/**
 * Get a split session's data by ID
 * @param userId - The owner user ID
 * @param splitSessionId - The split session ID
 * @returns Split session data if found, null otherwise
 */
export async function getSplitSessionData(
  userId: string,
  splitSessionId: string
): Promise<Record<string, any> | null> {
  try {
    const sessionDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("splitSessions")
      .doc(splitSessionId)
      .get();

    if (!sessionDoc.exists) {
      return null;
    }

    return sessionDoc.data() || null;
  } catch (error) {
    logger.error(
      `Error getting split session data for sessionId: ${splitSessionId}:`,
      error
    );
    return null;
  }
}

/**
 * Get all members of a group
 * @param userId - The owner user ID
 * @param groupId - The group ID
 * @returns Array of member documents
 */
export async function getGroupMembers(
  userId: string,
  groupId: string
): Promise<admin.firestore.DocumentData[]> {
  try {
    const snapshot = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("groups")
      .doc(groupId)
      .collection("members")
      .get();

    return snapshot.docs.map((doc) => doc.data());
  } catch (error) {
    logger.error(
      `Error getting group members for groupId: ${groupId}:`,
      error
    );
    return [];
  }
}
