import React, { useCallback, useContext, useState } from "react";
import {
  View,
  TouchableOpacity,
  Image,
  Text,
  StyleSheet,
  ActivityIndicator,
} from "react-native";
import { BottomSheetContext } from "./profileContext";
import { getUserProfile } from "./UserProfile";
import { useFocusEffect } from "@react-navigation/native";
import { useColorScheme } from "@/hooks/useColorScheme";

const HeaderWithMenu = () => {
  const { openBottomSheet } = useContext(BottomSheetContext);
  const [profile, setProfile] = useState(null); // State to store the user profile
  const [loading, setLoading] = useState(true); // State to track loading status
  const colorScheme = useColorScheme(); // Get the current color scheme

  // Fetch user profile whenever the screen is focused
  useFocusEffect(
    useCallback(() => {
      const fetchProfile = async () => {
        setLoading(true); // Start loading when the effect runs
        const userProfile = await getUserProfile();
        if (userProfile) {
          setProfile(userProfile.profile); // Store profile in state
        }
        setLoading(false); // Set loading to false after fetching
      };

      fetchProfile();

      return () => {};
    }, [])
  );

  if (loading) {
    return (
      <View style={styles.headerContainer}>
        <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
      </View>
    ); // Show loading spinner while fetching profile
  }

  return (
    <View style={styles.headerContainer}>
      <TouchableOpacity onPressIn={() => openBottomSheet()}>
        {profile ? (
          <Image
            source={{ uri: profile }} // Use profilePicture from the user profile
            style={styles.profileImage}
          />
        ) : (
          <View style={styles.placeholderContainer}>
            <Text style={[styles.placeholderText, { color: colorScheme === "dark" ? "#fff" : "#000" }]}>
              + Add Photo
            </Text>
          </View>
        )}
      </TouchableOpacity>
      <Text style={[styles.headerText,{ color: colorScheme === "dark" ? "#fff" : "#000" }]
    }>Home</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  headerContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 15,
    paddingLeft: 10,
  },
  profileImage: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  placeholderContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#ccc",
    justifyContent: "center",
    alignItems: "center",
  },
  placeholderText: {
    fontSize: 12,
  },
  headerText: {
    fontSize: 20,
    fontWeight: "bold",
  },
});

export default HeaderWithMenu;
