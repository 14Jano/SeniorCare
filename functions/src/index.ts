/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import * as logger from "firebase-functions/logger";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const onMedicationTaken = onDocumentUpdated(
  "users/{userId}/medications/{medId}",
  async (event) => {
    if (!event.data) {
      logger.log("Zdarzenie nie zawiera danych (event.data jest puste)");
      return;
    }
    const dataBefore = event.data.before.data();
    const dataAfter = event.data.after.data();
    const {userId, medId} = event.params;

    if (dataBefore?.isTaken === false && dataAfter?.isTaken === true) {
      logger.log(`Lek ${dataAfter.name} wzięty przez ${userId}`);
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        logger.error("Nie znaleziono użytkownika", {userId: userId});
        return;
      }
      const userData = userDoc.data();
      if (!userData || !userData.linkedAdminId) {
        logger.log(
          "Użytkownik nie jest połączony z żadnym adminem",
          {userId: userId},
        );
        return;
      }
      const adminId = userData.linkedAdminId;
      const adminDoc = await db.collection("users").doc(adminId).get();
      if (!adminDoc.exists) {
        logger.error("Nie znaleziono admina", {adminId: adminId});
        return;
      }

      const adminData = adminDoc.data();
      if (!adminData || !adminData.fcmToken) {
        logger.warn(
          "Admin nie ma zapisanego tokenu FCM",
          {adminId: adminId},
        );
        return;
      }
      const fcmToken = adminData.fcmToken;
      const body = `${userData.name} właśnie potwierdził wzięcie` +
        ` leku: ${dataAfter.name}.`;
      const payload = {
        notification: {
          title: "Podopieczny wziął lek! ✅",
          body: body,
          sound: "default",
        },
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "userId": userId,
          "medId": medId,
        },
      };

      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
        logger.log("Powiadomienie wysłane pomyślnie do:", fcmToken);
      } catch (error) {
        logger.error("Błąd wysyłania powiadomienia:", error);
      }
    }
    return; // Używamy return; (zamiast return null;) dla spójności
  },
);

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
// logger.info("Hello logs!", {structuredData: true});
// response.send("Hello from Firebase!");
// });
