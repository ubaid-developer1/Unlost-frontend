import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { ReminderItem } from "./fetchStoreReminder";

export const scheduleGroupedNotifications = async () => {
    try {
        let items = await AsyncStorage.getItem("reminderItems");
        const reminderItems: ReminderItem[] = items ? JSON.parse(items) : [];

        let dailyItems = reminderItems.filter((item) => item.frequency === "daily");
        let weeklyItems = reminderItems.filter((item) => item.frequency === "weekly");
        let monthlyItems = reminderItems.filter((item) => item.frequency === "monthly");

        // ✅ Cancel old notifications before scheduling new ones
        await Notifications.cancelAllScheduledNotificationsAsync();
        console.log("Cancelled all existing notifications");

        // ✅ Schedule Daily Notification
        if (dailyItems.length > 0) {
            let dailyMessage = dailyItems.map((item) => `- ${item.name}`).join("\n");
            await Notifications.scheduleNotificationAsync({
                content: {
                    title: "📅 Daily Reminder",
                    body: `You have these items:\n${dailyMessage}`,
                },
                trigger: {type:Notifications.SchedulableTriggerInputTypes.DAILY,hour:9,minute:0 }
            });

            
            
        }

        // ✅ Schedule Weekly Notification (Every Monday at 9 AM)
        if (weeklyItems.length > 0) {
            let weeklyMessage = weeklyItems.map((item) => `- ${item.name}`).join("\n");
            await Notifications.scheduleNotificationAsync({
                content: {
                    title: "🗓️ Weekly Reminder",
                    body: `Here are your weekly items:\n${weeklyMessage}`,
                },
                trigger: {type:Notifications.SchedulableTriggerInputTypes.WEEKLY, weekday: 1, hour: 9, minute: 0 } 
            });
            
        }

        // ✅ Schedule Monthly Notification (1st of every month at 10 AM)
        if (monthlyItems.length > 0) {
            let monthlyMessage = monthlyItems.map((item) => `- ${item.name}`).join("\n");
            await Notifications.scheduleNotificationAsync({
                content: {
                    title: "📆 Monthly Reminder",
                    body: `Here are your monthly items:\n${monthlyMessage}`,
                },
                trigger: {type:Notifications.SchedulableTriggerInputTypes.MONTHLY, day: 1, hour: 10, minute: 0}
            });
           
        }

    } catch (error) {
        console.error("Error scheduling notifications:", error);
    }
};