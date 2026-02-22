import test from "node:test";
import assert from "node:assert/strict";
import {
  buildMedicationNotificationPayload,
  shouldSendMedicationNotification,
} from "./medicationNotification";

test("should send notification when medication is marked as taken", () => {
  const result = shouldSendMedicationNotification(
    {isTaken: false, name: "Aspiryna"},
    {isTaken: true, name: "Aspiryna"},
  );

  assert.equal(result, true);
});

test("should not send notification when state does not change", () => {
  const result = shouldSendMedicationNotification(
    {isTaken: false, name: "Aspiryna"},
    {isTaken: false, name: "Aspiryna"},
  );

  assert.equal(result, false);
});

test("should not send notification when previous state is missing", () => {
  const result = shouldSendMedicationNotification(undefined, {
    isTaken: true,
    name: "Aspiryna",
  });

  assert.equal(result, false);
});

test("builds expected FCM payload", () => {
  const payload = buildMedicationNotificationPayload(
    "Jan",
    "Aspiryna",
    "user-1",
    "med-1",
  );

  assert.deepEqual(payload, {
    notification: {
      title: "Podopieczny wziął lek! ✅",
      body: "Jan właśnie potwierdził wzięcie leku: Aspiryna.",
      sound: "default",
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      userId: "user-1",
      medId: "med-1",
    },
  });
});
