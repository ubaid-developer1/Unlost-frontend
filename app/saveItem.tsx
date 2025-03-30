import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  useColorScheme,
  Alert,
} from "react-native";
import { Feather } from "@expo/vector-icons";
import { Picker } from "@react-native-picker/picker";
import { getUserProfile } from "@/components/ui/UserProfile";
import Toast from "react-native-toast-message";
import { router } from "expo-router";
import { environment } from "@/components/ui/environment";
import { Colors } from "@/constants/Colors";
import PremiumModal from "@/components/ui/PremiumModal";

const ReminderOptions = [
  { label: "Select Option", value: null },
  { label: "Daily", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
];

const AddItemForm = () => {
  const [selectedLocation, setSelectedLocation] = useState("");
  const [itemName, setItemName] = useState("");
  const [itemsList, setItemsList] = useState([]);
  const [exactLocation, setExactLocation] = useState("");
  const [borrowedTo, setBorrowedTo] = useState("");
  const [isLent, setIsLent] = useState(false);
  const [isBorrow, setIsBorrow] = useState(false);
  const [reminder, setReminder] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState(""); // For showing form error messages
  const [nameerrorMessage, setNameErrorMessage] = useState(""); // For showing form error messages
  const [reminderrorMessage, setRemindErrorMessage] = useState(""); // For showing form error messages
  const [successMessage, setSuccessMessage] = useState("");
  const [Location, setLocations] = useState([]);
  const [visible, setVisible] = useState(false); // For showing success message

  useEffect(() => {
    fetchLocations();
    fetchItems();
  }, []);

  const colorScheme = useColorScheme();
  const handleLocationChange = (itemValue) => {
    const selectedOption = Location.find((loc) => loc.value === itemValue);

    if (selectedOption?.premium) {
      setVisible(true);
      setSelectedLocation("");
    } else {
      setSelectedLocation(itemValue);
    }
  };
  const handleItemNameChange = (text) => setItemName(text);
  const handleExactLocationChange = (text) => setExactLocation(text);
  const handleBorrowedToChange = (text) => {
    setBorrowedTo(text);
    if (text) {
      setNameErrorMessage("")
    }
  }
  const handleReminderChange = (itemValue) => {
    setReminder(itemValue);
    setRemindErrorMessage("");
  }

  const fetchItems = async () => {
    try {
      const token = (await getUserProfile()).token;

      const response = await fetch(`${environment.development}/items`, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();

      if (response.ok) {
        setItemsList(data.items);
      } else {
        throw new Error(data.message || "Error fetching items");
      }
    } catch (error) {
      Toast.show({
        type: "error",
        text1: "Error fetching items",
        text2: error.message || "An error occurred while fetching items.",
      });
    }
  };

  const fetchLocations = async () => {
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
        // Map the response data to the correct structure (locationName as label)
        const fetchedLocations = data.locations.map((location) => ({
          label: location.locationName,
          value: location._id, // Using _id as value
        }));

        // Combine the static locations with the fetched ones and the "Add 10 more locations" at the end
        const updatedLocations = [
          { label: "Select Location", value: null },
          { label: "Add Custom Location", value: "custom", premium: true },
          ...fetchedLocations, // Add fetched locations
          {
            label: "Add 10 more locations",
            value: "custom",
            premium: true,
          },
        ];

        // Update the state with the combined list
        setLocations(updatedLocations);
      } else {
        console.error("Error fetching locations:", data.message);
      }
    } catch (error) {
      console.error("Error fetching locations:", error);
    }
  };
  const handleSubmit = async () => {
    if (itemsList?.length >= 100) {
      console.log(itemsList?.length)
      Toast.show({
        type: "error",
        text1: "Limit Exceeded",
        text2: "You can't go above 100 items!"
      });
      return;
    }
    if (!itemName || !selectedLocation || !exactLocation) {
      setErrorMessage("Please fill in all required fields");
      return;
    }
    if ((isLent || isBorrow) && !borrowedTo) {
      setNameErrorMessage("Name of Person is Required!");
      return;
    }

    if ((isLent || isBorrow) && !reminder) {
      setRemindErrorMessage("Reminder is Required!");
      return;
    }

    setLoading(true);
    setErrorMessage("");
    setNameErrorMessage("");
    setRemindErrorMessage("");
    setSuccessMessage("");

    const token = (await getUserProfile()).token;
    try {
      const response = await fetch(`${environment.development}/items/save`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          itemName: itemName,
          itemDescription: exactLocation,
          itemLocation: selectedLocation,
          itemReminder: (isLent || isBorrow) ? reminder : "",
          itemLentOrBorrowed: isLent ? "lent" : isBorrow ? "borrow" : "",
          itemLentOrBorrowedPersonName: (isLent || isBorrow) ? borrowedTo : "",
        }),
      });

      const data = await response.json();

      if (response.ok) {
        Toast.show({
          type: "success",
          text1: "Item Saved Successfully",
        });
        setTimeout(() => {
          router.navigate("/home");
        }, 1200);
      } else {
        setErrorMessage(
          data.message || "Something went wrong. Please try again."
        );
      }
    } catch (error) {
      console.error(error);
      setErrorMessage(
        "Failed to save item. Please check your connection and try again."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollView}>
      <View style={styles.container}>
        <View style={styles.headingContainer}>
          <Text style={styles.heading}>Add Item</Text>
        </View>

        <Text style={styles.label}>Select Location</Text>
        <Picker
          selectedValue={selectedLocation}
          onValueChange={handleLocationChange}
          style={styles.dropdown}
        >
          {Location.map((location, index) => (
            <Picker.Item
              key={index}
              label={
                location.premium ? `${location.label}   👑` : location.label
              }
              value={location.value}
              color={location.premium ? "grey" : "black"}
            />
          ))}
        </Picker>

        <Text style={styles.label}>Name of the Item</Text>
        <TextInput
          style={styles.input}
          value={itemName}
          onChangeText={handleItemNameChange}
          placeholder="Enter item name"
        />
        {errorMessage && !itemName && (
          <Text style={styles.errorText}>{errorMessage}</Text>
        )}

        <Text style={styles.label}>Detail Exact Location</Text>
        <TextInput
          style={styles.input}
          value={exactLocation}
          onChangeText={handleExactLocationChange}
          placeholder="Description"
        />
        {errorMessage && !exactLocation && (
          <Text style={styles.errorText}>{errorMessage}</Text>
        )}

        <Text style={styles.label}>Item Borrowed or Lent</Text>
        <View style={styles.radioContainer}>
          <TouchableOpacity
            style={[styles.radioButton, isLent && styles.selected]}
            onPress={() => {
              setIsLent(!isLent)
              setIsBorrow(false)
            }}
          >
            <Text style={styles.radioText}>Lent</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.radioButton, isBorrow && styles.selected]}
            onPress={() => {
              setIsBorrow(!isBorrow)
              setIsLent(false)
            }}
          >
            <Text style={styles.radioText}>Borrowed</Text>
          </TouchableOpacity>
        </View>

        {(isLent || isBorrow) && (
          <TextInput
            style={styles.input}
            value={borrowedTo}
            onChangeText={handleBorrowedToChange}
            placeholder="Name of person the item was lent to / borrowed from"
          />
        )}

        {nameerrorMessage && (
          <Text style={styles.errorText}>{nameerrorMessage}</Text>
        )}
        {
          (isLent || isBorrow) && (
            <>
              <Text style={styles.label}>Reminder</Text>
              <Picker
                selectedValue={reminder}
                onValueChange={handleReminderChange}
                style={styles.dropdown}
              >
                {ReminderOptions.map((option, index) => (
                  <Picker.Item
                    key={index}
                    label={option.label}
                    value={option.value}
                  />
                ))}
              </Picker>
            </>
          )
        }
        {reminderrorMessage && (
          <Text style={styles.errorText}>{reminderrorMessage}</Text>
        )}
        <TouchableOpacity
          style={styles.button}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator
              size="small"
              color={colorScheme === "dark" ? "#fff" : "#000"}
            />
          ) : (
            <Text style={styles.buttonText}>Save Item</Text>
          )}
        </TouchableOpacity>

        {successMessage && (
          <Text style={styles.successText}>{successMessage}</Text>
        )}
        {errorMessage && !successMessage && (
          <Text style={styles.errorText}>{errorMessage}</Text>
        )}

        <PremiumModal
          visible={visible}
          hideModal={() => setVisible(false)}
        ></PremiumModal>
        <Toast />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    flexGrow: 1,
    backgroundColor: Colors.light.backGroundColor,
    paddingTop: 80
  },
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
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: Colors.light.backGroundColor,
  },

  heading: {
    fontSize: 30,
    fontWeight: "bold",
    textAlign: "center",
    color: Colors.light.backGroundColor,
    textTransform: "uppercase",
    letterSpacing: 1.5,
  },
  label: {
    fontSize: 16,
    fontWeight: "500",
    color: Colors.light.buttonColor,
    marginBottom: 8,
  },
  input: {
    height: 55,
    borderColor: "#CCC",
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    marginBottom: 16,
  },
  dropdown: {
    backgroundColor: "#FFF",
    marginBottom: 16,
    height: 53,
    borderRadius: 5,
  },
  radioContainer: {
    flexDirection: "row",
    gap: 5,
    marginBottom: 16,
  },
  radioButton: {
    flex: 1,
    padding: 10,
    backgroundColor: "#E0E0E0",
    borderRadius: 8,
    alignItems: "center",
  },
  selected: {
    backgroundColor: Colors.light.buttonColor,
  },
  radioText: {
    color: "#FFF",
    fontWeight: "600",
  },
  button: {
    backgroundColor: Colors.light.buttonColor,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: "center",
    marginTop: 20,
  },
  buttonText: {
    color: "#FFF",
    fontWeight: "600",
    fontSize: 16,
  },
  errorText: {
    color: "red",
    fontSize: 14,
    marginBottom: 10,
  },
  successText: {
    color: "green",
    fontSize: 16,
    marginTop: 10,
  },
});

export default AddItemForm;
