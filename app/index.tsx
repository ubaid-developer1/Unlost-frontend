import React, { useCallback, useState } from "react";
import { View, Text, ActivityIndicator, StyleSheet } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router, useFocusEffect } from "expo-router"; // Ensure Expo Router is used for navigation

const Index = () => {
  const [loading, setLoading] = useState(true);

  useFocusEffect(
    useCallback(() => {
      let isActive = true; // To prevent state updates after unmount

      const checkUserToken = async () => {
        try {
          const token = await AsyncStorage.getItem("unlost_user_data");
          console.log("Stored Token:", token);

          if (isActive) {
            if (token) {
              router.replace("/home"); // Navigate to home if logged in
            } else {
              router.replace("/login"); // Navigate to login if no token
            }
          }
        } catch (error) {
          console.error("Error checking token", error);
          if (isActive) router.replace("/login");
        } finally {
          if (isActive) setLoading(false);
        }
      };

      checkUserToken();

      return () => {
        isActive = false; // Cleanup to prevent setting state on unmounted component
      };
    }, [router]) // Only depend on `router` to prevent unnecessary re-renders
  );

  if (loading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#000" />
      </View>
    );
  }

  return <View style={styles.container} />; // Prevent returning null for better structure
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    backgroundColor: "white",
    alignItems: "center",
  },
});

export default Index;
