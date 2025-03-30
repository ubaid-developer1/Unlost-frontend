import withAuthCheck from "@/components/ui/AuthChecker";
import { environment } from "@/components/ui/environment";
import { fetchAndStoreReminders } from "@/components/ui/fetchStoreReminder";
import { getUserProfile, updateProfile } from "@/components/ui/UserProfile";
import { Feather } from "@expo/vector-icons";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Link, router, useFocusEffect } from "expo-router";
import { useCallback, useContext, useEffect, useState } from "react";
import * as Notifications from "expo-notifications";
import BottomSheet, { BottomSheetView } from "@gorhom/bottom-sheet";
import * as ImagePicker from "expo-image-picker";
import { decode } from "base64-arraybuffer";

import {
  ActivityIndicator,
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  useColorScheme,
  View,
} from "react-native";
import {
  GestureHandlerRootView,
  TextInput,
} from "react-native-gesture-handler";
import Toast from "react-native-toast-message";
import { scheduleGroupedNotifications } from "@/components/ui/reminderService";
import { BottomSheetContext } from "@/components/ui/profileContext";
import * as FileSystem from "expo-file-system";
import { Colors } from "@/constants/Colors";
import { useAuth } from "@clerk/clerk-expo"; 


// Define colors for better maintainability
const colors = {
  primary: "#4CAF50",
  secondary: Colors.light.buttonColor,
  background: "#FFF",
  text: Colors.light.buttonColor,
  gray: "gray",
};

const Home = () => {
   const colorScheme = useColorScheme()
  const [searchQuery, setSearchQuery] = useState("");
  const [items, setItems] = useState(null);
  const [selectedItem, setSelectedItem] = useState(null);
  const [loading, setLoading] = useState(false);
  const [isSearchTriggered, setIsSearchTriggered] = useState(false);
  const [ProfilePicture, setProfilePicture] = useState(null);
  const [profile, setprofile] = useState(null);
  const {signOut} = useAuth()

  const fetchItems = async () => {
    if (!searchQuery.trim()) {
      setItems([]);
      return;
    }

    setLoading(true);
    const token = (await getUserProfile()).token;

    try {
      const response = await fetch(
        `${environment.development}/items/search?query=${searchQuery}`,
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setItems(data.items || []);
      } else {
        setItems([]);
        Toast.show({
          type: "error",
          text1: "Failed to fetch items",
        });
      }
    } catch (error) {
      setItems([]);
      console.error("Error fetching items:", error);
      Toast.show({
        type: "error",
        text1: "Error while fetching items",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (searchQuery.length > 0 && isSearchTriggered) {
        fetchItems();
      }
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery, isSearchTriggered]);

  useFocusEffect(
    useCallback(() => {
      setSearchQuery("");
      setSelectedItem(null);
      setIsSearchTriggered(false);
      setItems(null);
  
      const configureNotifications = async () => {
        Notifications.setNotificationHandler({
          handleNotification: async () => ({
            shouldShowAlert: true,
            shouldPlaySound: true,
            shouldSetBadge: true,
          }),
        });
      };
  
      configureNotifications();
  
      const checkLastRun = async () => {
        const lastRun = await AsyncStorage.getItem("lastReminderFetch");
        const today = new Date().toISOString().split("T")[0];
  
        if (lastRun !== today) {
          await fetchAndStoreReminders();
          await AsyncStorage.setItem("lastReminderFetch", today);
         
        }

        await scheduleGroupedNotifications(); 
      };
  
      checkLastRun();
  
      return () => {
        
      };
    }, [])
  );

  const handleSearchChange = (text) => {
    setSearchQuery(text);
    setIsSearchTriggered(true);
  };

  const handleItemSelect = (item) => {
    setSearchQuery(item.itemName);
    setSelectedItem(item._id);
    setIsSearchTriggered(false);
  };

  useEffect(() => {
    fetchUserData();
  }, []);

  const { isVisible, closeBottomSheet, bottomSheetRef } =
    useContext(BottomSheetContext);

  // Snap points for the bottom sheet
  

  const pickImage = async () => {
    // Ask for permission to access the camera/gallery
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (permission.granted) {
      let result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: true,
        aspect: [4, 3],
        base64: true,
      });

      if (!result.canceled) {
        setProfilePicture(result.assets[0].uri);
        setprofile(result.assets[0]);
      }
    }
  };

  const handleLogout = async () => {
    await AsyncStorage.removeItem("unlost_user_data");
    signOut().then(()=>{
      router.replace("/login");
    })
   
  };

  const [username, setusername] = useState("");
  const [email, setemail] = useState("");

  const [ProfileLoading, setProfileLoading] = useState(false);

  // Handle save changes
  const handleSaveChanges = async () => {
    setProfileLoading(true); // Start loading state
    try {
      // API call to update profile
      const token = (await getUserProfile()).token;

      // Prepare the base64 image (keep it as data:image/jpg;base64,)
      let base64Img = `data:image/jpg;base64,${profile.base64}`;

      // Add your Cloudinary cloud name and upload preset
      let apiUrl = `https://api.cloudinary.com/v1_1/dtdshav2n/image/upload`;

      // Prepare data for Cloudinary upload (as before)
      let dataImage = {
        file: base64Img, // Base64 image string
        upload_preset: "ml_default", // Your upload preset
      };

      // Cloudinary image upload request
      const imageResponse = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json", // Required header for JSON body
        },
        body: JSON.stringify(dataImage), // Sending the base64 data as JSON
      });

      const imageData = await imageResponse.json();
      if (!imageResponse.ok) {
        throw new Error("Error uploading image");
      }

      // Set the profile URL with the secure_url from Cloudinary
      setprofile(imageData.secure_url);

      // Now update the user profile in your backend with the new data
      const response = await fetch(
        `${environment.development}/user/updateProfile`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            username,
            email,
            profile: imageData.secure_url, // Use the image URL returned from Cloudinary
          }),
        }
      );

      const data = await response.json();
      if (response.ok) {
        await updateProfile(data.username, data.email, data.profile);
        await fetchUserData();
        Toast.show({
          type: "success",
          text1: "Profile Updated Successfully",
        });
      } else {
        Toast.show({
          type: "error",
          text1: "Error Updating Profile",
        });
      }
    } catch (error) {
      console.error(error);
      Toast.show({
        type: "error",
        text1: "Error Occurred Please try again",
      });
    } finally {
      setProfileLoading(false); // Stop loading state
    }
  };

  const fetchUserData = async () => {
    const storedUser = await getUserProfile(); // Get stored user data
    if (storedUser) {
      setusername(storedUser.username);
      setemail(storedUser.email);
      setprofile(storedUser.profile);
      setProfilePicture(null);
    }
  };

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ScrollView style={styles.container}>
        <View>
          {/* Heading */}
          <View style={styles.headingContainer}>
            <Text style={styles.heading}>What are you looking for?</Text>
          </View>

          {/* Search Bar */}
          <View style={styles.header}>
            <View style={styles.searchContainer}>
              <Feather
                name="search"
                size={20}
                color={colors.gray}
                style={styles.searchIcon}
              />
              <TextInput
                placeholder="Find my stuff!"
                placeholderTextColor={colors.gray}
                style={styles.searchBar}
                value={searchQuery}
                onChangeText={handleSearchChange}
                accessibilityLabel="Search input"
                accessibilityRole="search"
              />
            </View>
          </View>

          {/* Loading State */}
          {loading && <ActivityIndicator size="large" color={colors.primary} />}

          {!loading &&
            items &&
            items.length === 0 &&
            searchQuery.length > 0 && (
              <View style={styles.emptyState}>
                <Feather name="frown" size={24} color={colors.gray} />
                <Text style={styles.emptyStateText}>No items found</Text>
              </View>
            )}

          {/* Items List */}
          {!loading && items && items.length > 0 && !selectedItem && (
            <View>
              {items.map((item) => (
                <TouchableOpacity
                  onPress={() => handleItemSelect(item)}
                  key={item._id}
                  style={styles.itemContainer}
                  accessibilityLabel={`Select item ${item.itemName}`}
                  accessibilityRole="button"
                >
                  <Text style={styles.itemText}>{item.itemName}</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          {/* Buttons Section */}
          <TouchableOpacity
            disabled={!selectedItem}
            onPress={() => {
              if(selectedItem){
                router.push(`/singleItem?id=${selectedItem}`);
              }
             
            }}
            style={[
              styles.button,
              { backgroundColor: colors.primary, marginBottom: 20 },
            ]}
            accessibilityLabel="Find Item Now"
            accessibilityRole="button"
          >
            <Feather
              name="search"
              size={20}
              color="#FFF"
              style={styles.buttonIcon}
            />
            <Text style={styles.buttonText}>Find Item Now</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPressIn={() => {
              router.push("/saveItem");
            }}
            style={styles.button}
            accessibilityLabel="Save a New Item"
            accessibilityRole="button"
          >
            <Feather
              name="plus-circle"
              size={20}
              color="#FFF"
              style={styles.buttonIcon}
            />

            <Text style={styles.buttonText}>Save a New Item</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPressIn={() => {
              router.push("/editItem");
            }}
            style={styles.button}
            accessibilityLabel="Edit Item"
            accessibilityRole="button"
          >
            <Feather
              name="edit"
              size={20}
              color="#FFF"
              style={styles.buttonIcon}
            />
            <Link href="/editItem">
              <Text style={styles.buttonText}>Edit Items</Text>
            </Link>
          </TouchableOpacity>

          <TouchableOpacity
            onPressIn={() => {
              router.push("/editlocation");
            }}
            style={styles.button}
            accessibilityLabel="Edit Locations"
            accessibilityRole="button"
          >
            <Feather
              name="map-pin"
              size={20}
              color="#FFF"
              style={styles.buttonIcon}
            />

            <Text style={styles.buttonText}>Edit Locations</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      <Toast />

      <BottomSheet
        ref={bottomSheetRef}
        index={-1} // Start closed
        snapPoints={["25%", "50","80%"]} // Customize snap points as needed
        enablePanDownToClose
      >
        <BottomSheetView style={styles.contentContainer}>
          {/* Profile Picture */}
          <View style={styles.profilePictureContainer}>
            <TouchableOpacity onPress={pickImage}>
              <Image
                source={{ uri: ProfilePicture ? ProfilePicture : profile }}
                style={styles.profileImage}
              />
            </TouchableOpacity>
          </View>

          {/* User Profile Section */}
          <Text style={styles.title}>User Profile</Text>

          {/* Username */}
          <Text style={styles.label}>Username</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter your username"
            value={username}
            onChangeText={setusername}
          />

          {/* Email */}
          <Text style={styles.label}>Email</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter your email"
            keyboardType="email-address"
            value={email}
            onChangeText={setemail}
          />

          {/* Save Changes Button */}
          <TouchableOpacity
            style={styles.profilebutton}
            onPress={handleSaveChanges}
          >
            {ProfileLoading ? (
               <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
            ) : (
              <Text style={styles.buttonText}>Save Changes</Text>
            )}
          </TouchableOpacity>

          {/* Logout Button */}
          <TouchableOpacity
            onPressIn={handleLogout}
            style={[styles.profilebutton, styles.logoutButton]}
            onPress={handleLogout}
          >
            <Text style={styles.buttonText}>Logout</Text>
          </TouchableOpacity>
        </BottomSheetView>
      </BottomSheet>

      <Toast></Toast>
    </GestureHandlerRootView>
  );
};

// Styles (unchanged)
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 10,
  },
  headingContainer: {
    backgroundColor: "#f5f5f5",
    paddingVertical: 15,
    paddingHorizontal: 20,
    borderRadius: 10,
    marginBottom: 20,
    marginTop: 20,
    alignSelf: "center",
    width: "90%",
    elevation: 3,
  },
  heading: {
    fontSize: 30,
    fontWeight: "bold",
    color: colors.text,
    textAlign: "center",
    textTransform: "uppercase",
    letterSpacing: 1.5,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 15,
  },
  searchContainer: {
    flexDirection: "row",
    flex: 1,
    backgroundColor: colors.background,
    borderColor: colors.secondary,
    borderWidth: 1,
    borderRadius: 10,
    alignItems: "center",
    paddingHorizontal: 10,
  },
  searchIcon: {
    marginRight: 5,
  },
  searchBar: {
    color: colors.text,
    fontSize: 16,
    paddingVertical: 8,
    flex: 1,
  },
  button: {
    flexDirection: "row",
    alignItems: "center",
    width: "100%",
    backgroundColor: colors.secondary,
    borderRadius: 12,
    marginBottom: 10,
    paddingVertical: 15,
    marginTop: 15,
  },
  buttonIcon: {
    marginRight: 10,
    alignSelf: "center",
    width: "35%",
    textAlign: "right",
  },
  buttonText: {
    color: colors.background,
    fontSize: 18,
    fontWeight: "600",
  },
  itemContainer: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#ddd",
  },
  itemText: {
    fontSize: 18,
    color: colors.text,
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    marginTop: 20,
  },
  emptyStateText: {
    fontSize: 16,
    color: colors.gray,
    marginTop: 10,
  },


  contentContainer: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  profilePictureContainer: {
    alignItems: "center",
    marginBottom: 20,
  },
  profileImage: {
    width: 100,
    height: 100,
    borderRadius: 50,
    marginBottom: 10,
  },
  placeholderImage: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: "#d3d3d3",
    justifyContent: "center",
    alignItems: "center",
  },
  placeholderText: {
    color: "#fff",
    fontSize: 14,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
    textAlign: "center",
  },
  label: {
    fontSize: 14,
    fontWeight: "600",
    marginBottom: 5,
  },
  input: {
    height: 40,
    borderColor: "#ccc",
    borderWidth: 1,
    borderRadius: 8,
    paddingLeft: 10,
    marginBottom: 20,
  },
  profilebutton: {
    backgroundColor: "teal",
    paddingVertical: 12,
    borderRadius: 8,
    marginBottom: 15,
    justifyContent: "center",
    alignItems: "center",
  },
  profilebuttonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "bold",
  },
  logoutButton: {
    backgroundColor: "red",
  },
});

export default Home;
