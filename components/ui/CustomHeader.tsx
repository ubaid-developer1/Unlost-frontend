import React from "react";
import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { Feather } from "@expo/vector-icons";
import { useNavigation } from "expo-router";

const CustomHeader = ({ title }) => {
  const navigation = useNavigation();

  return (
    <View style={styles.header}>
      <TouchableOpacity onPress={() => navigation.goBack()}>
        <Feather name="arrow-left" size={24} color="white" />
      </TouchableOpacity>
      <Text style={styles.title}>{title}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    flexDirection: "row",
    alignItems:"center",
    paddingHorizontal: 20,
    paddingTop:50,
    paddingBottom:15,
    backgroundColor: "#333",
  },
  title: {
    fontSize: 20,
    fontWeight: "bold",
    color: "white",
    marginLeft:25,
  },
});

export default CustomHeader;
