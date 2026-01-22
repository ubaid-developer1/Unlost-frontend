import React, { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  TextInput,
  Switch,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
  ActivityIndicator,
} from "react-native";
import { Picker } from "@react-native-picker/picker";
import { Feather, Ionicons } from "@expo/vector-icons";
import { getUserProfile } from "@/components/ui/UserProfile"; // Assuming this function retrieves the user's profile for token.
import Toast from "react-native-toast-message";
import { environment } from "@/components/ui/environment";
import { useFocusEffect } from "expo-router";
import { Colors } from "@/constants/Colors";
import { router } from "expo-router";
import { isBorrowed, isLented } from "@/constants/others";
import CustomHeader from "@/components/ui/CustomHeader";
import DateTimePickerModal from 'react-native-modal-datetime-picker';
import { useColorScheme } from "@/hooks/useColorScheme.web";

const EditItemPage = () => {
  const [itemsList, setItemsList] = useState(null);
  const [selectedItem, setSelectedItem] = useState(null);
  const [itemName, setItemName] = useState("");
  const [description, setDescription] = useState("");
  const [selectedLocation, setSelectedLocation] = useState("");
  const [isLent, setIsLent] = useState(false);
  const [isBorrow, setIsBorrow] = useState(false);
  const [Location, setLocation] = useState([]);
  const [reminder, setReminder] = useState("");
  const [loading, setLoading] = useState(false); // For fetching item details
  const [isSaving, setIsSaving] = useState(false); // For save operation
  const [isDeleting, setIsDeleting] = useState(false); // For delete operation
  const [errMsg, setErrMsg] = useState("");
  const [errRemindMsg, setErrRemindMsg] = useState("");
  const [borrowedTo, setBorrowedTo] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearchTriggered, setIsSearchTriggered] = useState(false);
  const [sealoading, setSeaLoading] = useState(false); // For fetching item details
  const [isPickerVisible, setPickerVisible] = useState(false);
  const [selectedTime, setSelectedTime] = useState(null);
  const [fullloading, setFullLoading] = useState(false);


  // Fetch items when component loads
  useFocusEffect(
    useCallback(() => {
      // fetchItems();
      fetchLocations();
    }, [])
  );

  const colorScheme = useColorScheme();
  const ReminderOptions = [
    { label: "Select Option", value: null },
    { label: "Daily", value: "daily" },
    { label: "Weekly", value: "weekly" },
    { label: "Monthly", value: "monthly" },
  ];
  const showPicker = () => setPickerVisible(true);
  const hidePicker = () => setPickerVisible(false);
  const formatTime = (date) =>
    date?.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });

  function formatBackwardTime(hours, minutes) {
    const now = new Date(); // current date
    now.setHours(hours);
    now.setMinutes(minutes);
    now.setSeconds(0);
    now.setMilliseconds(0);
    return now;
  }

  const handleConfirm = (time) => {
    setSelectedTime(time);
    hidePicker();
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
        const fetchedLocations = data.locations.map((location) => ({
          label: location.locationName,
          value: location._id, // Using _id as value
        }));

        setLocation(fetchedLocations);
      } else {
        throw new Error(data.message || "Error fetching locations");
      }
    } catch (error) {
      Toast.show({
        type: "error",
        text1: "Error fetching locations",
        text2: error.message || "An error occurred while fetching locations.",
      });
      resetStates();
    }
    finally{
      setFullLoading(false)
    }
  };

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
      resetStates();
    }
  };

  // Fetch the details of the selected item
  // const fetchSelectedItem = async (itemId) => {
  //   if (!itemId) {
  //     resetStates();
  //     return;
  //   }
  //   setLoading(true); // Set loading to true when fetching the item
  //   try {
  //     const token = (await getUserProfile()).token;

  //     const response = await fetch(
  //       `${environment.development}/items/${itemId}`,
  //       {
  //         method: "GET",
  //         headers: {
  //           "Content-Type": "application/json",
  //           Authorization: `Bearer ${token}`,
  //         },
  //       }
  //     );

  //     const data = await response.json();

  //     if (response.ok) {
  //       const { item, itemLocationId } = data;
  //       console.log(item)
  //       setItemName(item.itemName);
  //       setDescription(item.itemDescription);
  //       setSelectedLocation(itemLocationId);
  //       setIsLent(item.itemLentOrBorrowed === "lent" && true);
  //       setIsBorrow(item.itemLentOrBorrowed === "borrow" && true);
  //       setBorrowedTo(item?.itemLentOrBorrowedPersonName)
  //       setReminder(item.itemReminder);
  //     } else {
  //       throw new Error(data.message || "Error fetching item details");
  //     }
  //   } catch (error) {
  //     Toast.show({
  //       type: "error",
  //       text1: "Error fetching item details",
  //       text2:
  //         error.message || "An error occurred while fetching item details.",
  //     });
  //     resetStates();
  //   } finally {
  //     setLoading(false); // Set loading to false once the fetch is complete
  //   }
  // };

  useFocusEffect(
    useCallback(() => {
      setSearchQuery("");
      setSelectedItem(null);
      setIsSearchTriggered(false);
      setItemsList(null);

      return () => {

      };
    }, [])
  );

  const fetchItemsSel = async () => {
    if (!searchQuery.trim()) {
      setItemsList([]);
      return;
    }

    setSeaLoading(true);
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
        setItemsList(data.items || []);
      } else {
        setItemsList([]);
        Toast.show({
          type: "error",
          text1: "Failed to fetch items",
        });
      }
    } catch (error) {
      setItemsList([]);
      console.error("Error fetching items:", error);
      Toast.show({
        type: "error",
        text1: "Error while fetching items",
      });
    } finally {
      setSeaLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (searchQuery.length > 0 && isSearchTriggered) {
        fetchItemsSel();
      }
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery, isSearchTriggered]);
  // Handle Update Item
  const handleUpdate = async () => {
    if (!selectedItem) {
      Alert.alert("Error", "Please select an item to update.");
      return;
    }

    if ((isLent || isBorrow) && !borrowedTo) {
      setErrMsg("Name is now required.")
      return;
    }

    if ((isLent || isBorrow) && !reminder) {
      setErrRemindMsg("Reminder is now required.")
      return;
    }
    if ((isLent || isBorrow) && !selectedTime) {
      setErrRemindMsg("Reminder is now required.");
      return;
    }

    const dates = new Date(selectedTime);
    const hour = dates.getHours();
    const minute = dates.getMinutes();

    const updatedItem = {
      itemName,
      itemDescription: description,
      itemLocation: selectedLocation,
      itemLentOrBorrowed: isLent ? "lent" : isBorrow ? "borrow" : "",
      itemReminder: (isLent || isBorrow) ? reminder : "",
      itemLentOrBorrowedPersonName: (isLent || isBorrow) ? borrowedTo : "",
      hours: (isLent || isBorrow) ? hour : 0,
      minutes: (isLent || isBorrow) ? minute : 0,
    };

    setIsSaving(true); // Start loading indicator

    try {
      const token = (await getUserProfile()).token;

      const response = await fetch(
        `${environment.development}/items/${selectedItem}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(updatedItem),
        }
      );

      const data = await response.json();

      if (response.ok) {
        Toast.show({
          type: "success",
          text1: "Item Updated Successfully",
        });
        fetchItems(); // Refresh items list
        resetStates();
        setTimeout(() => {
          router.navigate("/home");
        }, 1200);

      } else {
        throw new Error(data.message || "Error updating item");
      }
    } catch (error) {
      Toast.show({
        type: "error",
        text1: "Error updating item",
        text2: error.message || "An error occurred while updating the item.",
      });
      resetStates();
    } finally {
      setIsSaving(false); // Stop loading indicator
    }
  };

  // Handle Delete Item
  const handleDelete = async () => {

    if (!selectedItem) {
      Alert.alert("Error", "Please select an item to delete.");
      return;
    }

    Alert.alert("Delete Item", "Are you sure you want to delete this item?", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Delete",
        onPress: async () => {
          setIsDeleting(true); // Start loading indicator

          try {
            const token = (await getUserProfile()).token;

            const response = await fetch(
              `${environment.development}/items/${selectedItem}`,
              {
                method: "DELETE",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${token}`,
                },
              }
            );

            const data = await response.json();

            if (response.ok) {
              Toast.show({
                type: "success",
                text1: "Item Deleted Successfully",
              });
              fetchItems();
              resetStates(); // Refresh items list
              setTimeout(() => {
                router.navigate("/home");
              }, 1200);
            } else {
              throw new Error(data.message || "Error deleting item");
            }
          } catch (error) {
            Toast.show({
              type: "error",
              text1: "Error deleting item",
              text2:
                error.message || "An error occurred while deleting the item.",
            });
            resetStates();
          } finally {
            setIsDeleting(false); // Stop loading indicator
          }
        },
      },
    ]);
  };

  const handleSearchChange = (text) => {
    setSearchQuery(text);
    setIsSearchTriggered(true);
    setSelectedItem("");
  }

  const handleBorrowedToChange = (text) => {
    setBorrowedTo(text);
    if (text) {
      setErrMsg("");
    }
  }
  const handleReminderChange = (text) => {
    setReminder(text)
    setErrRemindMsg("");
  }

  const handleItemSelect = (item) => {
    setSearchQuery(item.itemName);
    setSelectedItem(item._id);
    setIsSearchTriggered(false);
    setItemName(item.itemName);
    setDescription(item.itemDescription);
    setSelectedLocation(item.itemLocation);
    setIsLent(item.itemLentOrBorrowed === "lent" && true);
    setIsBorrow(item.itemLentOrBorrowed === "borrow" && true);
    setBorrowedTo(item?.itemLentOrBorrowedPersonName)
    setReminder(item.itemReminder);
    setSelectedTime(item.hours !== 0 && item.minutes !== 0 ? formatBackwardTime(item.hours, item.minutes) : null)
  };

  // Function to reset the states in case of error
  const resetStates = () => {
    setItemName("");
    setDescription("");
    setSelectedLocation("");
    setIsLent(false);
    setIsBorrow(false);
    setBorrowedTo("");
    setErrMsg("")
    setErrRemindMsg("");
    setReminder("");
    setLoading(false);
    setSelectedItem(null);
    setSearchQuery("");
    setItemsList([]);
    setSeaLoading(false);
    setIsSearchTriggered(false);
    setFullLoading(false);
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
      <CustomHeader title={"Edit Item"} />
      <View style={styles.container}>
        <ScrollView showsVerticalScrollIndicator={false}>
          <View style={styles.headingContainer}>
            <Text style={styles.heading}>Edit Item</Text>
          </View>

          {/* Select Item Dropdown */}
          <Text style={styles.label}>Select Item</Text>
          {/* <Picker
          selectedValue={selectedItem}
          onValueChange={(itemValue) => {
            setSelectedItem(itemValue);
            fetchSelectedItem(itemValue);
          }}
          style={styles.picker}
        >
          <Picker.Item label="Select an item..." value={null} />
          {itemsList.map((item, index) => (
            <Picker.Item key={index} label={item.itemName} value={item._id} />
          ))}
        </Picker> */}
          <TextInput
            placeholder="Choose an Item"
            style={styles.input}
            value={searchQuery}
            onChangeText={handleSearchChange}
            accessibilityLabel="Search input"
            accessibilityRole="search"
          />

          {!sealoading &&
            itemsList &&
            itemsList.length === 0 &&
            searchQuery.length > 0 && (
              <View style={{ position: "relative" }}>
                <View style={{ backgroundColor: "#fff", padding: 10, borderRadius: 10, position: "absolute", top: 0, width: "100%", zIndex: 999, boxShadow: "1px 1px 20px gray", display: "flex", flexDirection: "column", alignItems: "center" }}>
                  <Feather name="frown" size={30} />
                  <Text style={{ fontSize: 16 }}>No items found</Text>
                </View>
              </View>
            )}
          {sealoading &&
            <View style={{ position: "relative" }}>
              <View style={{ backgroundColor: "#fff", padding: 10, borderRadius: 10, position: "absolute", top: 0, width: "100%", zIndex: 999, boxShadow: "1px 1px 20px gray" }}>
                <ActivityIndicator size="large" />
              </View>
            </View>
          }
          <View style={{ position: "relative" }}>
            {!sealoading && itemsList && itemsList.length > 0 && searchQuery && !selectedItem && (
              <View style={{ backgroundColor: "#fff", padding: 10, borderRadius: 10, position: "absolute", top: 0, width: "100%", zIndex: 999, boxShadow: "1px 1px 20px gray", maxHeight: 255, overflowY: "auto" }}>
                <ScrollView contentContainerStyle={{ flexGrow: 1 }}>
                  {itemsList.map((item) => (
                    <TouchableOpacity
                      onPress={() => handleItemSelect(item)}
                      key={item._id}
                      style={{ paddingTop: 8, paddingBottom: 8, marginTop: 4, marginBottom: 4, paddingLeft: 8, backgroundColor: "#ffd", borderRadius: 10 }}
                      // style={styles.itemContainer}
                      accessibilityLabel={`Select item ${item.itemName}`}
                      accessibilityRole="button"
                    >
                      <Text style={{ fontSize: 17 }}>{item.itemName}</Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            )}
          </View>


          {/* Show activity loader if loading */}
          {loading ? (
            <ActivityIndicator
              size="large"
              color="#0000ff"
              style={styles.loader}
            />
          ) : (
            <>
              {/* Rename Item */}
              <Text style={styles.label}>Rename Item</Text>
              <TextInput
                style={styles.input}
                placeholder="Enter new name"
                value={itemName}
                onChangeText={setItemName}
              />

              {/* Edit Description */}
              <Text style={styles.label}>Edit Location Details</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Enter description"
                value={description}
                onChangeText={setDescription}
                multiline
              />

              {/* Move to Another Location */}
              <Text style={styles.label}>Move to Another Location</Text>
              <Picker
                selectedValue={selectedLocation}
                onValueChange={(location) => setSelectedLocation(location)}
                style={styles.picker}
              >
                <Picker.Item label="Select a location..." value={null} />
                {Location.map((loc, index) => (
                  <Picker.Item key={index} label={loc.label} value={loc.value} />
                ))}
              </Picker>
              {/* Lent or Borrowed Toggle */}
              <Text style={styles.label}>Item Borrowed or Lent</Text>
              <View style={styles.radioContainer}>
                <TouchableOpacity
                  style={[styles.radioButton, isLent && styles.selected]}
                  onPress={() => {
                    setIsLent(!isLent);
                    setIsBorrow(false);
                  }}
                >
                  <Text style={styles.radioText}>Lent</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.radioButton, isBorrow && styles.selected]}
                  onPress={() => {
                    setIsBorrow(!isBorrow);
                    setIsLent(false);
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
                  placeholder="Name of the person"
                />
              )}

              {/* Reminder Toggle */}


              {errMsg && (
                <Text style={styles.errorText}>{errMsg}</Text>
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

              {errRemindMsg && (
                <Text style={styles.errorText}>{errRemindMsg}</Text>
              )}
              {/* Buttons */}
              <View style={styles.buttonContainer}>
                <TouchableOpacity
                  style={styles.deleteButton}
                  onPress={handleDelete}
                  disabled={isDeleting} // Disable button while deleting
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

                <TouchableOpacity
                  style={styles.saveButton}
                  onPress={handleUpdate}
                  disabled={isSaving} // Disable button while saving
                >
                  {isSaving ? (
                    <ActivityIndicator color="white" />
                  ) : (
                    <>
                      <Ionicons name="save" size={20} color="white" />
                      <Text style={styles.saveButtonText}>Save</Text>
                    </>
                  )}
                </TouchableOpacity>
              </View>

            </>
          )}
          <Toast />
        </ScrollView>
      </View>
    </>
  );
};

// Styles
const styles = StyleSheet.create({
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
  errorText: {
    color: "red",
    fontSize: 14,
    marginBottom: 10,
  },
  dropdown: {
    backgroundColor: "#FFF",
    marginBottom: 16,
    // height: 50,
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
  // scrollContainer: {
  //   flexGrow: 1,
  //   backgroundColor: Colors.light.backGroundColor,
  //   paddingTop: 80

  // },
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: Colors.light.backGroundColor,
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
  heading: {
    fontSize: 30,
    fontWeight: "bold",
    textAlign: "center",
    color: Colors.light.backGroundColor,
    textTransform: "uppercase",
    letterSpacing: 1.5,
  },
  label: {
    fontSize: 15,
    fontWeight: "600",
    color: Colors.light.buttonColor,
    textTransform: "uppercase",
    marginBottom: 5,
  },
  picker: {
    borderColor: "#ccc",
    borderWidth: 1,
    borderRadius: 5,
    marginBottom: 15,
  },
  input: {
    borderColor: "#ccc",
    borderWidth: 1,
    borderRadius: 5,
    height: 50,
    paddingHorizontal: 10,
    marginBottom: 15,
    fontSize: 16,
  },
  textArea: {
    height: 80,
    textAlignVertical: "top",
  },
  switchContainer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 15,
  },
  buttonContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 20,
  },
  deleteButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "red",
    padding: 15,
    borderRadius: 5,
    width: "48%",
    justifyContent: "center",
  },
  deleteButtonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "bold",
    marginLeft: 5,
  },
  saveButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "green",
    padding: 15,
    borderRadius: 5,
    width: "48%",
    justifyContent: "center",
  },
  saveButtonText: {
    color: "white",
    fontSize: 16,
    fontWeight: "bold",
    marginLeft: 5,
  },
  loader: {
    marginVertical: 20,
  },
});

export default EditItemPage;
