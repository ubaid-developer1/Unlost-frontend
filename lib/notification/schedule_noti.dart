import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:unstop/main.dart';

Future<void> scheduleNotification({
  required String itemId, // 🆕 Pass itemId
  required String title,
  required String body,
  required TimeOfDay time,
  required String frequency,
}) async {
  try {
    // ✅ Validate inputs
    if (itemId.isEmpty || title.isEmpty || body.isEmpty || frequency.isEmpty) {
      debugPrint('❌ Invalid notification parameters');
      return;
    }

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // ✅ Log the time being scheduled for debugging
    debugTimeInfo(time, 'Scheduling');
    debugPrint('⏰ Scheduled date: $scheduledDate');

    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.inexact;

    if (Platform.isAndroid) {
      final androidFlutterLocalNotificationsPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // ✅ Request exact alarm permission with better error handling
      try {
        final granted = await androidFlutterLocalNotificationsPlugin?.requestExactAlarmsPermission();
        if (granted == true) {
          androidScheduleMode = AndroidScheduleMode.exact;
          debugPrint('✅ Exact alarms permission granted');
        } else {
          debugPrint('⚠️ Exact alarms permission not granted. Using inexact.');
          debugPrint('💡 For reliable reminders, enable: Settings > Apps > Un-Lost > Special app access > Schedule exact alarms');
        }
      } catch (e) {
        debugPrint('⚠️ Could not request exact alarms permission: $e');
        debugPrint('💡 Using inexact scheduling - reminders may be delayed by Android battery optimization');
      }
    }

    final scheduleTime = _getNextScheduledDate(scheduledDate, frequency);

    debugPrint('⏰ Final scheduled time: ${scheduleTime.toString()}');
    debugPrint('⏰ Timezone: ${tz.local}');

    // ✅ Cancel any existing notification for this item
    await cancelNotification(itemId);

    // ✅ FIXED: Schedule multiple notifications for reliable recurring behavior
    await _scheduleRecurringNotifications(
      itemId,
      title,
      body,
      scheduleTime,
      frequency,
      androidScheduleMode,
    );

    debugPrint('✅ Notification scheduled successfully for item: $itemId');
    
    // 🧪 TESTING: Show scheduled notification details
    debugPrint('🧪 TESTING INFO:');
    debugPrint('   📅 First notification: ${scheduleTime.toString()}');
    debugPrint('   🔄 Frequency: $frequency');
    debugPrint('   📊 Total notifications scheduled: 30');
    if (frequency == 'Daily') {
      debugPrint('   📅 Next 3 days: ${scheduleTime.add(const Duration(days: 1))}, ${scheduleTime.add(const Duration(days: 2))}, ${scheduleTime.add(const Duration(days: 3))}');
    } else if (frequency == 'Weekly') {
      debugPrint('   📅 Next 3 weeks: ${scheduleTime.add(const Duration(days: 7))}, ${scheduleTime.add(const Duration(days: 14))}, ${scheduleTime.add(const Duration(days: 21))}');
    }
  } catch (e) {
    debugPrint('❌ Error scheduling notification: $e');
  }
}

// 🆕 Cancel old notification before updating
Future<void> cancelNotification(String itemId) async {
  try {
    // Cancel the main notification
    await flutterLocalNotificationsPlugin.cancel(itemId.hashCode);
    
    // Cancel all recurring notifications (up to 30 occurrences)
    for (int i = 1; i < 30; i++) {
      int notificationId = itemId.hashCode + i;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
    
    debugPrint('✅ Cancelled all notifications for item: $itemId');
  } catch (e) {
    debugPrint('❌ Error cancelling notification: $e');
  }
}

// 🆕 NEW: Disable notifications for a specific item
Future<void> disableNotificationsForItem(String itemId) async {
  try {
    await cancelNotification(itemId);
    debugPrint('🔕 Notifications disabled for item: $itemId');
  } catch (e) {
    debugPrint('❌ Error disabling notifications for item: $itemId');
  }
}

// 🆕 NEW: Disable all notifications (nuclear option)
Future<void> disableAllNotifications() async {
  try {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🔕 All notifications disabled');
  } catch (e) {
    debugPrint('❌ Error disabling all notifications: $e');
  }
}

// 🆕 NEW: Check if notifications are enabled for an item
Future<bool> areNotificationsEnabledForItem(String itemId) async {
  try {
    final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final itemNotifications = pendingNotifications.where((notification) => 
      notification.id == itemId.hashCode || 
      notification.id == itemId.hashCode + 1 ||
      notification.id == itemId.hashCode + 2
    ).toList();
    
    return itemNotifications.isNotEmpty;
  } catch (e) {
    debugPrint('❌ Error checking notification status: $e');
    return false;
  }
}

// ✅ NEW: Utility function to debug time parsing
void debugTimeInfo(TimeOfDay time, String context) {
  final hour24 = time.hour;
  final minute = time.minute;
  final isPM = hour24 >= 12;
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  final ampm = isPM ? 'PM' : 'AM';
  
  debugPrint('🔍 Time Debug [$context]:');
  debugPrint('  24-hour: ${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  debugPrint('  12-hour: ${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm');
  debugPrint('  TimeOfDay.hour: ${time.hour}, TimeOfDay.minute: ${time.minute}');
}

tz.TZDateTime _getNextScheduledDate(DateTime dateTime, String frequency) {
  final now = tz.TZDateTime.now(tz.local);
  final scheduled = tz.TZDateTime.from(dateTime, tz.local);

  // ✅ FIXED: Only push to next occurrence if the time has already passed today
  if (scheduled.isBefore(now)) {
    switch (frequency) {
      case 'Daily':
        return scheduled.add(const Duration(days: 1));
      case 'Weekly':
        return scheduled.add(const Duration(days: 7));
      case 'Monthly':
        return tz.TZDateTime(
          tz.local,
          scheduled.year,
          scheduled.month + 1,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
        );
      default:
        return scheduled;
    }
  }
  return scheduled;
}

// ✅ NEW: Reliable recurring notification scheduling
Future<void> _scheduleRecurringNotifications(
  String itemId,
  String title,
  String body,
  tz.TZDateTime firstScheduleTime,
  String frequency,
  AndroidScheduleMode androidScheduleMode,
) async {
  try {
    // Schedule the first notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      itemId.hashCode,
      title,
      body,
      firstScheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'Your channel description',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      payload: itemId,
      matchDateTimeComponents: null, // Don't rely on matchDateTimeComponents
    );

    // Schedule additional notifications for the next 30 occurrences
    int maxOccurrences = 30; // Reasonable limit to avoid too many notifications
    
    for (int i = 1; i < maxOccurrences; i++) {
      tz.TZDateTime nextTime;
      
      switch (frequency) {
        case 'Daily':
          nextTime = firstScheduleTime.add(Duration(days: i));
          break;
        case 'Weekly':
          nextTime = firstScheduleTime.add(Duration(days: i * 7));
          break;
        case 'Monthly':
          nextTime = tz.TZDateTime(
            tz.local,
            firstScheduleTime.year,
            firstScheduleTime.month + i,
            firstScheduleTime.day,
            firstScheduleTime.hour,
            firstScheduleTime.minute,
          );
          break;
        default:
          return; // Don't schedule for unknown frequencies
      }

      // Use a unique ID for each occurrence
      int notificationId = itemId.hashCode + i;
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        nextTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'Your channel description',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        payload: itemId,
        matchDateTimeComponents: null,
      );
    }
    
    debugPrint('✅ Scheduled $maxOccurrences recurring notifications for $frequency frequency');
  } catch (e) {
    debugPrint('❌ Error scheduling recurring notifications: $e');
  }
}

// 🧪 TESTING: Function to check scheduled notifications
Future<void> testScheduledNotifications() async {
  try {
    final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint('🧪 TESTING: Found ${pendingNotifications.length} scheduled notifications');
    
    for (var notification in pendingNotifications) {
      debugPrint('   📱 ID: ${notification.id}, Title: ${notification.title}');
    }
  } catch (e) {
    debugPrint('❌ Error checking scheduled notifications: $e');
  }
}

// 🧪 TESTING: Function to schedule a test notification in 1 minute
Future<void> scheduleTestNotification() async {
  try {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 1));
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
    
    // ✅ Check and request exact alarms permission
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexact;
    
    if (Platform.isAndroid) {
      final androidFlutterLocalNotificationsPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final granted = await androidFlutterLocalNotificationsPlugin?.requestExactAlarmsPermission();
      if (granted == true) {
        scheduleMode = AndroidScheduleMode.exact;
        debugPrint('🧪 TEST: Exact alarms permission granted');
      } else {
        debugPrint('🧪 TEST: Exact alarms permission not granted, using inexact mode');
        debugPrint('💡 Go to Settings > Apps > Un-Lost > Special app access > Schedule exact alarms');
      }
    }
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      99999, // Unique test ID
      '🧪 Test Notification',
      'This is a test notification to verify the system works',
      tzTestTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications for debugging',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode, // ✅ Use the determined schedule mode
      payload: 'test',
      matchDateTimeComponents: null,
    );
    
    debugPrint('🧪 TEST: Notification scheduled for ${testTime.toString()}');
    debugPrint('🧪 TEST: Schedule mode: ${scheduleMode.toString()}');
    debugPrint('🧪 TEST: Wait 1 minute to see if notification appears');
    
    if (scheduleMode == AndroidScheduleMode.inexact) {
      debugPrint('⚠️ WARNING: Using inexact scheduling - notification may be delayed by Android');
    }
  } catch (e) {
    debugPrint('❌ Error scheduling test notification: $e');
    debugPrint('💡 SOLUTION: Enable exact alarms permission in Android settings');
  }
}

// 🧪 TESTING: Function to help users enable exact alarms permission
Future<void> showExactAlarmsPermissionGuide() async {
  debugPrint('🔧 EXACT ALARMS PERMISSION GUIDE:');
  debugPrint('   1. Go to Android Settings');
  debugPrint('   2. Navigate to: Apps > Un-Lost');
  debugPrint('   3. Tap "Special app access"');
  debugPrint('   4. Tap "Schedule exact alarms"');
  debugPrint('   5. Toggle ON "Allow schedule exact alarms"');
  debugPrint('   6. Return to the app and try again');
  debugPrint('');
  debugPrint('💡 This permission is required for reliable reminder notifications');
  debugPrint('💡 Without it, notifications may be delayed by Android battery optimization');
}

