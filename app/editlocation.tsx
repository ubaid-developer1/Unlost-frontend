import React, { useCallback, useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
  ActivityIndicator,
  useColorScheme,
  TouchableWithoutFeedback,
} from "react-native";
import { Picker } from "@react-native-picker/picker";
import { FontAwesome5, Ionicons } from "@expo/vector-icons";
import { getUserProfile } from "@/components/ui/UserProfile";
import Toast from "react-native-toast-message";
import { environment } from "@/components/ui/environment";
import { useFocusEffect } from "expo-router";
import { Colors } from "@/constants/Colors";
import PremiumModal from "@/components/ui/PremiumModal";
import CustomHeader from "@/components/ui/CustomHeader";
import CustomLocModal from "@/components/ui/customLocModal";

const EditLocationsPage = () => {
  const [selectedLocation, setSelectedLocation] = useState(null);
  const [newLocationName, setNewLocationName] = useState("");
  const [selectedDeleteLocation, setSelectedDeleteLocation] = useState(null);
  const [Location, setLocation] = useState([]);
  const [customLocation, setCustomLocation] = useState(null);
  const [customLocationLimit, setCustomLocationLimit] = useState();
  const [isSaving, setIsSaving] = useState(false); // For save operation
  const [isDeleting, setIsDeleting] = useState(false); // For delete operation
  const [custLocVisible, setCustLocVisible] = useState(false);
  const [fullloading, setFullLoading] = useState(false);

  const colorScheme = useColorScheme()

  useFocusEffect(
    useCallback(() => {
      fetchLocations()
      return () => { };
    }, [])
  );

  const [visible, setVisible] = useState(false);

  const fetchLocations = async () => {
    setFullLoading(true)
    try {
      const token = (await getUserProfile()).token;

      const response = await fetch(`${environment.development}/locations`, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();

      if (response.ok) {
        const fetchedLocations = data.locations.map((location) => ({
          label: location.locationName,
          value: location._id, // Using _id as value
        }));

        setLocation(fetchedLocations);
        setCustomLocation(data.customLocation);
        setCustomLocationLimit(data.limit)
      } else {
        console.error("Error fetching locations:", data.message);
      }
    } catch (error) {
      console.error("Error fetching locations:", error);
    }
    finally{
      setFullLoading(false)
    }
  };

  // Handle Save (Edit Location)
  const handleSave = async () => {
    if (!selectedLocation || !newLocationName.trim()) {
      Alert.alert("Error", "Please select a location and provide a new name.");
      return;
    }

    setIsSaving(true); // Start loading indicator

    try {
      const token = (await getUserProfile()).token;
      const response = await fetch(
        `${environment.development}/locations/edit/${selectedLocation}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ newLocationName }),
        }
      );

      const data = await response.json();

      if (response.ok) {
        Toast.show({
          type: "success",
          text1: "Location Updated Successfully",
        });
        fetchLocations();
        setNewLocationName("");
      } else {
        Alert.alert("Error", data.message || "Failed to rename location.");
      }
    } catch (error) {
      console.error("Error saving location:", error);
      Alert.alert("Error", "An error occurred while renaming the location.");
    } finally {
      setIsSaving(false); // Stop loading indicator
    }
  };

  // Handle Delete Location
  // const handleDelete = async () => {
  //   if (!selectedDeleteLocation) {
  //     Alert.alert("Error", "Please select a location to delete.");
  //     return;
  //   }

  //   Alert.alert(
  //     "Delete Location",
  //     "Warning: Deleting this location will remove it permanently. Proceed?",
  //     [
  //       { text: "Cancel", style: "cancel" },
  //       {
  //         text: "Delete",
  //         onPress: async () => {
  //           setIsDeleting(true); // Start loading indicator

  //           try {
  //             const token = (await getUserProfile()).token;
  //             const response = await fetch(
  //               `${environment.development}/locations/delete/${selectedDeleteLocation}`,
  //               {
  //                 method: "DELETE",
  //                 headers: {
  //                   "Content-Type": "application/json",
  //                   Authorization: `Bearer ${token}`,
  //                 },
  //               }
  //             );

  //             const data = await response.json();

  //             if (response.ok) {
  //               Toast.show({
  //                 type: "success",
  //                 text1: "Location Deleted Successfully",
  //               });
  //               fetchLocations(); // Refresh the location list
  //             } else {
  //               Alert.alert("Error", data.message || "Failed to delete location.");
  //             }
  //           } catch (error) {
  //             console.error("Error deleting location:", error);
  //             Alert.alert("Error", "An error occurred while deleting the location.");
  //           } finally {
  //             setIsDeleting(false); // Stop loading indicator
  //           }
  //         },
  //       },
  //     ]
  //   );
  // };

  if (fullloading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center", backgroundColor: colorScheme === "dark" ? "#000000" : "#ffffff" }}>
        <ActivityIndicator
          size="large"
          color={colorScheme === "dark" ? "#ffffff" : "#000000"}
        />
      </View>
    );
  }

  return (
    <>
      <CustomHeader title={"Edit Location"} />
      <View style={styles.container}>
        <ScrollView showsVerticalScrollIndicator={false}>
          {/* Section 1: Edit Location */}
          <View style={styles.headingContainer}>
            <Text style={styles.heading}>Edit Location</Text>
          </View>


          <Text style={styles.label}>Select To Rename</Text>
          <Picker
            selectedValue={selectedLocation}
            onValueChange={(itemValue) => setSelectedLocation(itemValue)}
            style={styles.picker}
          >
            <Picker.Item label="Select a location..." value={null} />
            {Location.map((loc, index) => (
              <Picker.Item key={index} label={loc.label} value={loc.value} />
            ))}
          </Picker>

          <Text style={styles.label}>Rename Location</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter new name"
            value={newLocationName}
            onChangeText={setNewLocationName}
          />

          <TouchableOpacity
            disabled={!selectedLocation || isSaving}
            style={styles.saveButton}
            onPress={handleSave}
          >
            {isSaving ? (
              <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
            ) : (
              <>
                <Ionicons name="save" size={20} color="white" />
                <Text style={styles.saveButtonText}>Save</Text>
              </>
            )}
          </TouchableOpacity>

          {/* Section 2: Premium - Add Custom Location */}
          <View
            style={{
              flexDirection: "row",
              gap: 10,
              justifyContent: "space-between",
            }}
          >
            <Text style={styles.header}>Add More Locations</Text>
            <FontAwesome5 name="crown" color="gold" size={25} />
          </View>

          <TouchableOpacity onPress={() => setVisible(true)} style={[styles.input, styles.disabledInput]}>
            <Text style={{ color: "black" }}>
              Upgrade Now to Add 10
              Custom Locations
            </Text>
          </TouchableOpacity>

          {/* Section 3: Delete Location */}
          <Text style={styles.header}>Delete Custom Location</Text>

          {/* <Text style={styles.label}>Select Location to Delete</Text> */}
          {
            customLocationLimit && customLocationLimit > 0 ? (
              <Picker
                selectedValue={selectedDeleteLocation}
                onValueChange={(itemValue) => setSelectedDeleteLocation(itemValue)}
                style={styles.picker}
              >
                <Picker.Item label="Select a location..." value={null} />
                {customLocation && customLocation.map((loc, index) => (
                  <Picker.Item key={index} label={loc.label} value={loc.value} />
                ))}
              </Picker>
            ) : (
              <TouchableOpacity onPress={() => setCustLocVisible(true)}>
                <View pointerEvents="none">
                  <Picker
                    selectedValue={selectedDeleteLocation}
                    style={styles.picker}
                  >
                    <Picker.Item label="Select a location..." value={null} />
                    {customLocation && customLocation.map((loc, index) => (
                      <Picker.Item key={index} label={loc.label} value={loc.value} />
                    ))}
                  </Picker>
                </View>
              </TouchableOpacity>
            )
          }

          <Text style={styles.warningText}>
            ⚠️ Warning: Move all items to another location before deleting this location to prevent loss of items
          </Text>

          <TouchableOpacity
            disabled={!selectedDeleteLocation || isDeleting}
            style={styles.deleteButton}
          // onPress={handleDelete}
          >
            {isDeleting ? (
              <ActivityIndicator color="black" />
            ) : (
              <>
                <Ionicons name="trash" size={20} color={"#fff"} />
                <Text style={styles.deleteButtonText}>Delete</Text>
              </>
            )}
          </TouchableOpacity>
        </ScrollView>

        <Toast />

        <PremiumModal visible={visible} hideModal={() => setVisible(false)}></PremiumModal>
        <CustomLocModal visible={custLocVisible} hideModal={() => setCustLocVisible(false)}></CustomLocModal>
      </View>
    </>
  );
};

// Styles (unchanged)
const styles = StyleSheet.create({
  // scrollContainer: {
  //   flexGrow: 1,
  //   backgroundColor: "#fff",
  //   paddingTop:80
  // },
  headingContainer: {
    backgroundColor: Colors.light.buttonColor,
    paddingVertical: 15,
    paddingHorizontal: 15,
    borderRadius: 10,
    marginTop: 10,
    marginBottom: 10,
    alignSelf: "center",
    width: "100%",
    elevation: 3, // Adds a slight shadow
  },
  heading: {
    fontSize: 30,
    fontWeight: "bold",
    textAlign: "center",
    color: Colors.light.backGroundColor,
    textTransform: "uppercase",
    letterSpacing: 1.5,
  },
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  header: {
    fontSize: 20,
    fontWeight: "bold",
    color: Colors.light.buttonColor,
    marginBottom: 10,
  },
  label: {
    fontSize: 15,
    fontWeight: "600",
    color: Colors.light.buttonColor,
    marginBottom: 5,
    textTransform: "uppercase",
  },
  picker: {
    borderColor: "#ccc",
    borderWidth: 1,
    borderRadius: 5,
    marginBottom: 15,
  },
  input: {
    height: 50,
    borderColor: "#ccc",
    borderWidth: 1,
    borderRadius: 5,
    paddingHorizontal: 10,
    marginBottom: 15,
    fontSize: 16,
  },
  disabledInput: {
    backgroundColor: "#f0f0f0",
    justifyContent: "center",
    alignItems: "center",
    height: 50,
  },
  warningText: {
    color: "red",
    fontSize: 14,
    fontWeight: "bold",
    marginBottom: 15,
    textAlign: "center",
  },
  saveButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "green",
    padding: 15,
    borderRadius: 5,
    justifyContent: "center",
    marginBottom: 20,
  },
  saveButtonText: {
    color: "white",
    fontSize: 16,
    fontWeight: "bold",
    marginLeft: 5,
  },
  deleteButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "red",
    padding: 15,
    borderRadius: 5,
    justifyContent: "center",
  },
  deleteButtonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "bold",
    marginLeft: 5,
  },
});

export default EditLocationsPage;