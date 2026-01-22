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
  Button,
} from "react-native";
import { Feather } from "@expo/vector-icons";
import { Picker } from "@react-native-picker/picker";
import { getUserProfile } from "@/components/ui/UserProfile";
import Toast from "react-native-toast-message";
import { router } from "expo-router";
import { environment } from "@/components/ui/environment";
import { Colors } from "@/constants/Colors";
import PremiumModal from "@/components/ui/PremiumModal";
import CustomHeader from "@/components/ui/CustomHeader";
import DateTimePickerModal from 'react-native-modal-datetime-picker';
import LimitModal from "@/components/ui/LimitModal";
import AddLimModal from "@/components/ui/addLimitModal";

const ReminderOptions = [
  { label: "Select Notification", value: null },
  { label: "Daily", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
];

const AddItemForm = () => {
  const [selectedLocation, setSelectedLocation] = useState("");
  const [itemName, setItemName] = useState("");
  const [itemsList, setItemsList] = useState([]);
  const [itemsLimit, setItemsLimit] = useState<number>();
  const [exactLocation, setExactLocation] = useState("");
  const [borrowedTo, setBorrowedTo] = useState("");
  const [isLent, setIsLent] = useState(false);
  const [isBorrow, setIsBorrow] = useState(false);
  const [reminder, setReminder] = useState("");
  const [loading, setLoading] = useState(false);
  const [fullloading, setFullLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState(""); // For showing form error messages
  const [nameerrorMessage, setNameErrorMessage] = useState(""); // For showing form error messages
  const [reminderrorMessage, setRemindErrorMessage] = useState(""); // For showing form error messages
  const [successMessage, setSuccessMessage] = useState("");
  const [Location, setLocations] = useState([]);
  const [customLocation, setCustomLocations] = useState(null);
  const [customLimit, setCustomLimit] = useState(null);
  const [visible, setVisible] = useState(false); // For showing success message
  const [moreVisible, setMoreVisible] = useState(false); // For showing success message
  const [limitVisible, setLimitVisible] = useState(false);
  const [isPickerVisible, setPickerVisible] = useState(false);
  const [selectedTime, setSelectedTime] = useState(null);

  useEffect(() => {
    fetchLocations();
    fetchItems();
  }, []);

  // useEffect(() => {
  //   const dates = new Date(selectedTime);
  //   console.log(dates.getHours() , dates.getMinutes())
  // }, [selectedTime])

  useEffect(() => {
    if (itemsLimit && itemsList?.length >= itemsLimit) {
      setLimitVisible(true)
    } else {
      setLimitVisible(false)
    }
  }, [itemsLimit])

  const colorScheme = useColorScheme();
  const handleLocationChange = (itemValue) => {
    const selectedOption = Location.find((loc) => loc.value === itemValue);

    if (selectedOption?.premium) {
      setSelectedLocation("");
      if (customLimit && customLocation.length >= customLimit) {
        setVisible(true);
      } else {
        setVisible(false);
        router.push("/editlocation");
      }
    } else {
      setSelectedLocation(itemValue);
    }
  };
  const showPicker = () => setPickerVisible(true);
  const hidePicker = () => setPickerVisible(false);

  const handleConfirm = (time) => {
    setSelectedTime(time);
    hidePicker();
  };

  const formatTime = (date) =>
    date?.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
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
    setFullLoading(true)
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
        setItemsLimit(data.limit);
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
    finally {
      setFullLoading(false)
    }
  };

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
        setCustomLocations(data.customLocation);
        setCustomLimit(data.limit)
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
    finally {
      setFullLoading(false)
    }
  };
  const handleSubmit = async () => {
    if (itemsList?.length >= itemsLimit) {
      setLimitVisible(true)
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
    if ((isLent || isBorrow) && !selectedTime) {
      setRemindErrorMessage("Reminder is Required!");
      return;
    }

    setLoading(true);
    setErrorMessage("");
    setNameErrorMessage("");
    setRemindErrorMessage("");
    setSuccessMessage("");

    const dates = new Date(selectedTime);
    const hour = dates.getHours();
    const minute = dates.getMinutes();

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
          hours: (isLent || isBorrow) ? hour : 0,
          minutes: (isLent || isBorrow) ? minute : 0,
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
      <CustomHeader title={"Save Item"} />
      <View style={styles.container}>
        <ScrollView showsVerticalScrollIndicator={false}>
          <View style={styles.headingContainer}>
            <Text style={styles.heading}>Add a new Item</Text>
          </View>

          <Text style={styles.label}>Choose Where To Save</Text>
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

          <Text style={styles.label}>Exact Location Details</Text>
          <TextInput
            style={styles.input}
            value={exactLocation}
            onChangeText={handleExactLocationChange}
            placeholder="Description"
          />
          {errorMessage && !exactLocation && (
            <Text style={styles.errorText}>{errorMessage}</Text>
          )}

          <Text style={styles.label}>Select If Borrowed or Lent</Text>
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
              placeholder="Type name of person"
            />
          )}

          {nameerrorMessage && (
            <Text style={styles.errorText}>{nameerrorMessage}</Text>
          )}
          {
            (isLent || isBorrow) && (
              <>
                <Text style={styles.label}>Set a Reminder</Text>
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
          {
            (isLent || isBorrow) && (
              <>
                <TouchableOpacity
                  style={styles.timeModal}
                  onPress={showPicker}
                >
                  {selectedTime ? (
                    <Text style={styles.timeModalText}>
                      {formatTime(selectedTime)}
                    </Text>
                  ) : (
                    <Text style={styles.timeModalText}>Select Time</Text>
                  )
                  }
                </TouchableOpacity>
                {/* <Button title="Select Time" onPress={showPicker} /> */}
                <DateTimePickerModal
                  isVisible={isPickerVisible}
                  mode="time"
                  onConfirm={handleConfirm}
                  onCancel={hidePicker}
                  is24Hour={false} // this enables AM/PM format
                />

              </>
            )
          }
          {reminderrorMessage && (
            <Text style={styles.errorTextTwo}>{reminderrorMessage}</Text>
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
              <Text style={styles.buttonText}>Save</Text>
            )}
          </TouchableOpacity>

          {successMessage && (
            <Text style={styles.successText}>{successMessage}</Text>
          )}
          {errorMessage && !successMessage && (
            <Text style={styles.errorText}>{errorMessage}</Text>
          )}
          {
            itemsLimit && (
              <View style={{ marginTop: 15, display: "flex", flexDirection: "column", alignItems: "center" }}>
                <Text style={{ fontSize: 20, fontWeight: "500" }}>{itemsList.length} of {itemsLimit} Items Saved</Text>
                <TouchableOpacity
                  // style={styles.button}
                  onPress={() => setMoreVisible(true)}
                // disabled={loading}
                >
                  <Text style={{ color: Colors.light.buttonColor, fontSize: 17, fontWeight: "500" }}>Add 50 More Now</Text>
                </TouchableOpacity>
              </View>
            )
          }

          <PremiumModal
            visible={visible}
            hideModal={() => setVisible(false)}
          ></PremiumModal>
          <AddLimModal visible={moreVisible}
            hideModal={() => setMoreVisible(false)}></AddLimModal>

          <LimitModal
            visible={limitVisible}
            hideModal={() => setLimitVisible(false)}
          >
          </LimitModal>
          <Toast />
        </ScrollView>
      </View>
    </>
  );
};

const styles = StyleSheet.create({
  // scrollView: {
  //   flexGrow: 1,
  //   backgroundColor: Colors.light.backGroundColor,
  //   paddingTop: 80
  // },
  timeModal: {
    backgroundColor: "#cfcec4",
    paddingLeft: 17,
    paddingTop: 10,
    paddingBottom: 10,
    borderRadius: 5
  },
  timeModalText: {
    fontSize: 16
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
    fontSize: 25,
    fontWeight: "bold",
    textAlign: "center",
    color: Colors.light.backGroundColor,
    textTransform: "uppercase",
    letterSpacing: 1.5,
  },
  label: {
    fontSize: 15,
    fontWeight: "500",
    color: Colors.light.buttonColor,
    marginBottom: 8,
    textTransform: "uppercase",
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
    backgroundColor: "green",
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
  errorTextTwo: {
    color: "red",
    fontSize: 14,
    marginBottom: 10,
    marginTop: 6
  },
  successText: {
    color: "green",
    fontSize: 16,
    marginTop: 10,
  },
});

export default AddItemForm;
