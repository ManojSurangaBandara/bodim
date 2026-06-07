const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Triggered whenever a room document is updated.
 * If the room transitions to "approved" status, we:
 *   1. Fetch all saved_alerts.
 *   2. Match each alert's filters against the newly-approved room.
 *   3. Send a multicast FCM push to all matching devices.
 *   4. Clean up stale / invalid FCM tokens from Firestore.
 */
exports.notifyOnRoomApproved = onDocumentUpdated(
  "rooms/{roomId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when a room is newly approved from a pending/rejected state.
    // Resuming a paused ad also sets status to "approved", but should not
    // trigger the approval notification.
    if (after.status !== "approved" || before.status === "approved" || before.status === "paused") {
      return null;
    }

    const room = after;
    const roomPrice = parsePrice(room.price);

    const db = getFirestore();
    const alertsSnapshot = await db.collection("saved_alerts").get();

    if (alertsSnapshot.empty) return null;

    // Step 1: Find which userIds have at least one alert matching this room.
    // Also track alert-level tokens for users who have no userId stored.
    const matchingUserIds = new Set();
    const standaloneTokens = []; // alerts with no userId — match individually

    for (const doc of alertsSnapshot.docs) {
      const alert = doc.data();
      if (!matchesAlert(alert, room, roomPrice)) continue;

      if (alert.userId) {
        matchingUserIds.add(alert.userId);
      } else if (alert.fcmToken) {
        standaloneTokens.push({ token: alert.fcmToken, alertId: doc.id, userId: null });
      }
    }

    // Step 2: For each matched userId, fetch ALL their registered FCM tokens
    // from users/{uid}.fcmTokens — this covers every device they've ever
    // logged in from (Android + web), regardless of which device saved the alert.
    const tokens = [];
    const seenTokens = new Set();

    if (matchingUserIds.size > 0) {
      const userDocs = await Promise.all(
        Array.from(matchingUserIds).map((uid) =>
          db.collection("users").doc(uid).get()
        )
      );
      for (const userDoc of userDocs) {
        if (!userDoc.exists) continue;
        const data = userDoc.data();
        const userTokens = Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
        // Also include the legacy single fcmToken field if not in array yet.
        if (data.fcmToken && !userTokens.includes(data.fcmToken)) {
          userTokens.push(data.fcmToken);
        }
        for (const token of userTokens) {
          if (token && !seenTokens.has(token)) {
            seenTokens.add(token);
            tokens.push({ token, alertId: null, userId: userDoc.id });
          }
        }
      }
    }

    // Step 3: Add standalone (no-userId) matched tokens as fallback.
    for (const entry of standaloneTokens) {
      if (!seenTokens.has(entry.token)) {
        seenTokens.add(entry.token);
        tokens.push(entry);
      }
    }

    const messaging = getMessaging();
    const roomId = event.params.roomId;

    // ── Notify the ad owner that their listing was approved ──────────────────
    const ownerUid = room.userId;
    if (ownerUid) {
      const ownerDoc = await db.collection("users").doc(ownerUid).get();
      if (ownerDoc.exists) {
        const ownerData = ownerDoc.data();
        const ownerTokens = Array.isArray(ownerData.fcmTokens) ? [...ownerData.fcmTokens] : [];
        if (ownerData.fcmToken && !ownerTokens.includes(ownerData.fcmToken)) {
          ownerTokens.push(ownerData.fcmToken);
        }
        if (ownerTokens.length > 0) {
          const ownerTitle = "Your ad has been approved!";
          const ownerBody = room.title
            ? `"${room.title}" is now live.`
            : "Your listing is now live and visible to everyone.";
          const ownerResponse = await messaging.sendEachForMulticast({
            tokens: ownerTokens,
            notification: { title: ownerTitle, body: ownerBody },
            android: { notification: { channelId: "bodim_alerts", priority: "high" } },
            data: { roomId, type: "ad_approved" },
          });
          // Clean up stale owner tokens.
          const ownerCleanup = [];
          ownerResponse.responses.forEach((res, idx) => {
            if (
              !res.success &&
              res.error &&
              (res.error.code === "messaging/registration-token-not-registered" ||
                res.error.code === "messaging/invalid-registration-token")
            ) {
              ownerCleanup.push(
                db.collection("users").doc(ownerUid).update({
                  fcmTokens: FieldValue.arrayRemove(ownerTokens[idx]),
                }).catch(() => {})
              );
            }
          });
          if (ownerCleanup.length > 0) await Promise.all(ownerCleanup);
        }
      }
    }

    // ── Notify users with matching saved alerts ───────────────────────────────
    if (tokens.length === 0) return null;

    const category = room.category && room.category.trim()
      ? room.category.trim()
      : "Bodim";
    const title = `New ${category} Available!`;
    const body = buildBody(room);

    // Send in batches of 500 (FCM multicast limit).
    const batchSize = 500;
    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      const response = await messaging.sendEachForMulticast({
        tokens: batch.map((t) => t.token),
        notification: { title, body },
        android: {
          notification: {
            channelId: "bodim_alerts",
            priority: "high",
          },
        },
        data: {
          roomId,
          district: room.district ?? "",
          town: room.town ?? "",
        },
      });

      // Remove invalid tokens from Firestore.
      const deleteOps = [];
      response.responses.forEach((res, idx) => {
        if (
          !res.success &&
          res.error &&
          (res.error.code ===
            "messaging/registration-token-not-registered" ||
            res.error.code === "messaging/invalid-registration-token")
        ) {
          const entry = batch[idx];
          if (entry.userId) {
            // User-level token: remove stale token from the fcmTokens array.
            deleteOps.push(
              db.collection("users").doc(entry.userId).update({
                fcmTokens: FieldValue.arrayRemove(entry.token),
              }).catch(() => {})
            );
          } else if (entry.alertId) {
            // Legacy standalone alert: delete the alert document.
            deleteOps.push(
              db.collection("saved_alerts").doc(entry.alertId).delete()
            );
          }
        }
      });

      if (deleteOps.length > 0) {
        await Promise.all(deleteOps);
      }
    }

    return null;
  }
);

exports.notifyAdminsOnPendingAd = onDocumentCreated(
  'rooms/{roomId}',
  async (event) => {
    const room = event.data.data();
    if (!room || room.status !== 'pending') return null;
    return sendAdminsPendingNotification(room, event.params.roomId);
  }
);

exports.notifyAdminsOnPendingAdUpdate = onDocumentUpdated(
  'rooms/{roomId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!after) return null;
    if (after.status !== 'pending' || before?.status === 'pending') return null;
    return sendAdminsPendingNotification(after, event.params.roomId);
  }
);

async function sendAdminsPendingNotification(room, roomId) {
  const db = getFirestore();
  const adminSnapshot = await db.collection('users').where('isAdmin', '==', true).get();
  if (adminSnapshot.empty) return null;

  const tokens = [];
  const seenTokens = new Set();

  for (const adminDoc of adminSnapshot.docs) {
    const adminData = adminDoc.data();
    const adminTokens = Array.isArray(adminData.fcmTokens) ? [...adminData.fcmTokens] : [];
    if (adminData.fcmToken && !adminTokens.includes(adminData.fcmToken)) {
      adminTokens.push(adminData.fcmToken);
    }

    for (const token of adminTokens) {
      if (token && !seenTokens.has(token)) {
        seenTokens.add(token);
        tokens.push({ token, userId: adminDoc.id });
      }
    }
  }

  if (tokens.length === 0) return null;

  const title = 'New pending ad needs review';
  const body = room.title
    ? `"${room.title}" is waiting for approval.`
    : 'A new listing is waiting for admin review.';

  const messaging = getMessaging();
  const batchSize = 500;

  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    const response = await messaging.sendEachForMulticast({
      tokens: batch.map((entry) => entry.token),
      notification: { title, body },
      android: {
        notification: {
          channelId: 'bodim_alerts',
          priority: 'high',
        },
      },
      data: { roomId, type: 'pending_ad' },
    });

    const deleteOps = [];
    response.responses.forEach((res, idx) => {
      if (
        !res.success &&
        res.error &&
        (res.error.code === 'messaging/registration-token-not-registered' ||
          res.error.code === 'messaging/invalid-registration-token')
      ) {
        deleteOps.push(
          db.collection('users').doc(batch[idx].userId).update({
            fcmTokens: FieldValue.arrayRemove(batch[idx].token),
          }).catch(() => {}),
        );
      }
    });

    if (deleteOps.length > 0) {
      await Promise.all(deleteOps);
    }
  }

  return null;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Extract a numeric price from a string like "LKR 15,000/month" or "15000".
 * Returns null if not parseable.
 */
function parsePrice(priceStr) {
  if (!priceStr) return null;
  const digits = String(priceStr).replace(/[^0-9]/g, "");
  const num = parseInt(digits, 10);
  return isNaN(num) ? null : num;
}

/**
 * Returns true if the room satisfies every filter in the alert.
 * A null filter field means "any".
 */
function matchesAlert(alert, room, roomPrice) {
  const norm = (v) => (v ?? "").trim().toLowerCase();
  if (alert.district && norm(alert.district) !== norm(room.district)) return false;
  if (alert.town && norm(alert.town) !== norm(room.town)) return false;
  if (alert.category && norm(alert.category) !== norm(room.category)) return false;

  if (roomPrice !== null) {
    if (alert.minPrice !== null && alert.minPrice !== undefined) {
      if (roomPrice < alert.minPrice) return false;
    }
    if (alert.maxPrice !== null && alert.maxPrice !== undefined) {
      if (roomPrice > alert.maxPrice) return false;
    }
  }

  return true;
}

/**
 * Build a short human-readable notification body from a room document.
 */
function buildBody(room) {
  const parts = [];
  if (room.district) parts.push(room.district);
  if (room.town) parts.push(room.town);
  if (room.price) parts.push(room.price);
  return parts.length > 0
    ? parts.join(" · ")
    : "A new listing matches your saved alert.";
}
