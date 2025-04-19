import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { ReminderItem } from "./fetchStoreReminder";

export const scheduleGroupedNotifications = async () => {
    try {
        let items = await AsyncStorage.getItem("reminderItems");
        console.log(items,"items")
        const reminderItems: ReminderItem[] = items ? JSON.parse(items) : [];

        let dailyItems = reminderItems.filter((item) => item.frequency === "daily");
        let weeklyItems = reminderItems.filter((item) => item.frequency === "weekly");
        let monthlyItems = reminderItems.filter((item) => item.frequency === "monthly");

        // ✅ Cancel old notifications before scheduling new ones
        await Notifications.cancelAllScheduledNotificationsAsync();
        console.log("Cancelled all existing notifications");

        // ✅ Schedule Daily Notification
        if (dailyItems.length > 0) {
            for (const item of dailyItems) {
                const items: any = item;
                const dailyMessage = items.lentBorrow === "lent" ? `${items.name} was Lent to ${items.personName}` : items.lentBorrow === "borrow" ? `${items.name} was Borrowed from ${items.personName}` : "";
                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: "📅 Daily Reminder",
                        body: dailyMessage,
                    },
                    trigger: { type: Notifications.SchedulableTriggerInputTypes.DAILY, hour: items.hour, minute: items.minute }
                });
            }
            // let dailyMessage = dailyItems.map((item) => `- ${item.name}`).join("\n");   
        }

        // ✅ Schedule Weekly Notification (Every Monday at 9 AM)
        if (weeklyItems.length > 0) {
            // let weeklyMessage = weeklyItems.map((item) => `- ${item.name}`).join("\n");
            for (const item of weeklyItems) {
                const items: any = item;
                const weeklyMessage = items.lentBorrow === "lent" ? `${items.name} was Lent to ${items.personName}` : items.lentBorrow === "borrow" ? `${items.name} was Borrowed from ${items.personName}` : "";
                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: "🗓️ Weekly Reminder",
                        body: weeklyMessage,
                    },
                    trigger: { type: Notifications.SchedulableTriggerInputTypes.WEEKLY, weekday: 1, hour: items.hour, minute: items.minute }
                });
            }

        }

        // ✅ Schedule Monthly Notification (1st of every month at 10 AM)
        if (monthlyItems.length > 0) {
            // let monthlyMessage = monthlyItems.map((item) => `- ${item.name}`).join("\n");
            for (const item of monthlyItems) {
                const items: any = item;
                const monthlyMessage = items.lentBorrow === "lent" ? `${items.name} was Lent to ${items.personName}` : items.lentBorrow === "borrow" ? `${items.name} was Borrowed from ${items.personName}` : "";
                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: "📆 Monthly Reminder",
                        body: monthlyMessage,
                    },
                    trigger: { type: Notifications.SchedulableTriggerInputTypes.MONTHLY, day: 1, hour: items.hour, minute: items.minute }
                });
            }

        }

    } catch (error) {
        console.error("Error scheduling notifications:", error);
    }
};