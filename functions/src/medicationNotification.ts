export interface MedicationState {
  isTaken?: boolean;
  name?: string;
}

export interface NotificationPayload {
  notification: {
    title: string;
    body: string;
    sound: string;
  };
  data: {
    click_action: string;
    userId: string;
    medId: string;
  };
}

export const shouldSendMedicationNotification = (
  before: MedicationState | undefined,
  after: MedicationState | undefined,
): boolean => {
  return before?.isTaken === false && after?.isTaken === true;
};

export const buildMedicationNotificationPayload = (
  userName: string,
  medicationName: string,
  userId: string,
  medId: string,
): NotificationPayload => {
  return {
    notification: {
      title: "Podopieczny wziął lek! ✅",
      body: `${userName} właśnie potwierdził wzięcie leku: ${medicationName}.`,
      sound: "default",
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      userId,
      medId,
    },
  };
};
