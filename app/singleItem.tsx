import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  TouchableOpacity,
} from "react-native";
import axios from "axios"; // Make sure you install axios (npm install axios)
import { getUserProfile } from "@/components/ui/UserProfile";
import { useLocalSearchParams } from "expo-router";
import { environment } from "@/components/ui/environment";
import { Colors } from "@/constants/Colors";
import { ScrollView } from "react-native";

const SingleItem = () => {
  const { id } = useLocalSearchParams();
  const [itemData, setItemData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchItemData = async () => {
      const token = (await getUserProfile()).token;
      try {
        const response = await axios.get(
          `${environment.development}/items/${id}`,
          {
            headers: {
              Authorization: `Bearer ${token}`, // Replace with the actual token if available
            },
          }
        );
        setItemData(response.data.item); // Assuming the response contains the item data under 'item'
        setLoading(false);
      } catch (err) {
        setError("An error occurred while fetching the item data.");
        setLoading(false);
      }
    };

    fetchItemData();
  }, [id]);

  if (loading) {
    return (
      <SafeAreaView style={[styles.container, styles.loaderContainer]}>
        <ActivityIndicator size="large" color="#0000ff" />
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.errorText}>{error}</Text>
      </SafeAreaView>
    );
  }

  const updatedDate = new Date(itemData.updatedAt);
  const createdDate = new Date(itemData.createdAt);
  // const updatedDatesDate = `${updatedDate?.getDate()}/${updatedDate?.getMonth()+1}/${updatedDate?.getFullYear()}`;
  //  const updatedDatesTime = `${updatedDate?.getHours()}:${updatedDate?.getMinutes()}`
  //   const createdDatesDate = `${createdDate?.getDate()}/${createdDate?.getMonth()+1}/${createdDate?.getFullYear()}`;
  //  const createdDatesTime = `${createdDate?.getHours()}:${createdDate?.getMinutes()}`

  const updatedDatesDate = `${String(updatedDate.getMonth() + 1).padStart(2, '0')}/${String(updatedDate.getDate()).padStart(2, '0')}/${updatedDate.getFullYear()}`;
  const updatedDatesTime = updatedDate.toLocaleString([],{
    minute:"2-digit",
    hour:"2-digit"
  })

  const createdDatesDate = `${String(createdDate.getMonth() + 1).padStart(2, '0')}/${String(createdDate.getDate()).padStart(2, '0')}/${createdDate.getFullYear()}`;
  const createdDatesTime = createdDate.toLocaleString([],{
    minute:"2-digit",
    hour:'2-digit'
  })

  return (
    <ScrollView contentContainerStyle={styles.scrollView}>
      <SafeAreaView style={styles.container}>
        <View style={styles.headingContainer}>
          <Text style={styles.heading}>{itemData.itemLocation}</Text>
        </View>

        <View style={styles.content}>
          <View style={styles.card}>
            <Text style={styles.label}>ITEM:</Text>
            <Text style={styles.value}>{itemData.itemName}</Text>

            <Text style={styles.label}>DESCRIPTION:</Text>
            <Text style={styles.value}>{itemData.itemDescription}</Text>

            <Text style={styles.label}>LENT / BORROWED</Text>
            
            
            <Text style={styles.value}>
              {itemData.itemLentOrBorrowed ? itemData.itemLentOrBorrowedPersonName : "Item Not Exchanged"}
            </Text>

            <Text style={[styles.label,{textAlign:"center",fontSize:16 , backgroundColor:Colors.light.buttonColor , color:"#fff" , padding:10 , borderRadius:10}]}>Item Last Updated</Text>
            <Text style={[styles.value, { textAlign: "center" }]}>
              {updatedDatesDate}{"     "}
              {updatedDatesTime}
              {/* Format date if needed */}
            </Text>

            <Text style={[styles.label,{textAlign:"center",fontSize:16 , backgroundColor:Colors.light.buttonColor , color:"#fff" , padding:10 , borderRadius:10}]}>Original File Date</Text>
            <Text style={[styles.value, { textAlign: "center" }]}>
              {createdDatesDate}{"     "}
              {createdDatesTime}
              {/* Format date if needed */}
            </Text>

            {/* <TouchableOpacity style={styles.button}>
              <Text style={styles.buttonText}>Item History</Text>
            </TouchableOpacity> */}
          </View>
        </View>
      </SafeAreaView>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  loaderContainer: {
    justifyContent: "center",
    alignItems: "center",
  },
  scrollView: {
    flexGrow: 1,
    backgroundColor: Colors.light.background,
  },
  container: {
    flex: 1,
    backgroundColor: Colors.light.background,
  },

  content: {
    flex: 1,
    padding: 20,
  },
  card: {
    backgroundColor: "#FFF",
    borderRadius: 10,
    padding: 20,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 5,
  },
  label: {
    color: Colors.light.buttonColor,
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 6,
  },
  historyLabel: {
    marginTop: 10,
    fontSize: 17,
    fontWeight: "700",
    color: "#2C3E50",
  },
  value: {
    color: "black",
    fontSize: 18,
    marginBottom: 16,
    lineHeight: 24,
  },
  headingContainer: {
    backgroundColor: Colors.light.buttonColor,
    paddingVertical: 15,
    paddingHorizontal: 15,
    borderRadius: 10,
    marginTop: 20,
    alignSelf: "center",
    width: "90%",
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
  errorText: {
    textAlign: "center",
    color: "red",
    fontSize: 18,
    marginTop: 20,
  },
  button: {
    width: "100%",
    backgroundColor: Colors.light.buttonColor,
    borderRadius: 12,
    paddingVertical: 15,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 20,
  },
  buttonText: {
    color: "#FFF",
    fontSize: 18,
    fontWeight: "600",
  },
});

export default SingleItem;
