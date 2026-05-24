const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
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

    // Only fire when a room is newly approved.
    if (before.status === "approved" || after.status !== "approved") {
      return null;
    }

    const room = after;
    const roomPrice = parsePrice(room.price);

    const db = getFirestore();
    const alertsSnapshot = await db.collection("saved_alerts").get();

    if (alertsSnapshot.empty) return null;

    const tokens = [];

    for (const doc of alertsSnapshot.docs) {
      const alert = doc.data();

      if (!alert.fcmToken) continue;
      if (!matchesAlert(alert, room, roomPrice)) continue;

      tokens.push({ token: alert.fcmToken, alertId: doc.id });
    }

    if (tokens.length === 0) return null;

    const category = room.category && room.category.trim()
      ? room.category.trim()
      : "Bodim";
    const title = `New ${category} Available!`;
    const body = buildBody(room);

    const messaging = getMessaging();

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
          roomId: event.params.roomId,
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
          const alertId = batch[idx].alertId;
          deleteOps.push(
            db.collection("saved_alerts").doc(alertId).delete()
          );
        }
      });

      if (deleteOps.length > 0) {
        await Promise.all(deleteOps);
      }
    }

    return null;
  }
);

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
