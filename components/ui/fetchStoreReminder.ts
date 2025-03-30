import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { environment } from "./environment";
import { getUserProfile } from "./UserProfile";
import { scheduleGroupedNotifications } from "./reminderService";

export interface ReminderItem {
  id: string;
  name: string;
  frequency: "daily" | "weekly" | "monthly"; // Added "monthly"
}

// ✅ Fetch reminders from API and store them locally
export const fetchAndStoreReminders = async () => {
  try {
    const token = (await getUserProfile()).token;

    const response = await fetch(`${environment.development}/items/reminders`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    const data: ReminderItem[] = await response.json();

    if (data.length > 0) {
      console.log("DB Data: ",data)
      await AsyncStorage.setItem("reminderItems", JSON.stringify(data));
      console.log("Reminders stored successfully!");

      // ✅ Schedule notifications after storing reminders
      await scheduleGroupedNotifications();
    }
  } catch (error) {
    console.error("Error fetching reminders:", error);
  }
};
