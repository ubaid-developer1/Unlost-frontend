import React, { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, Image, StyleSheet, ActivityIndicator, useColorScheme, ScrollView } from "react-native";
import { useNavigation } from '@react-navigation/native'; // Using Expo's react-navigation
import { router } from "expo-router";
import { environment } from "@/components/ui/environment";
import Stepper from "@/components/ui/ProgressStepper";
import { Colors } from "@/constants/Colors";

const ForgotPasswordScreen = () => {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false); // State to track the loading status
  const colorScheme = useColorScheme()
  const handleRequestReset = async () => {
   
    if (!email) {
      alert("Please enter your email address.");
      return;
    }

    setLoading(true); 

    try {
    const response = await fetch(`${environment.development}/forget-password/request-reset`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });

      const data = await response.json();
      console.log(data)

      if (response.ok) {
        router.push(`/verifyotp?email=${email}`)
      } else {
        alert(data.message || "Something went wrong. Please try again.");
      }
    } catch (error) {
      console.log(error)
      alert("An error occurred. Please try again.");
    } finally {
      setLoading(false); // Stop the loader once the request is complete
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
    <View style={styles.container}>
      <Text style={styles.title}>Forgot Password?</Text>
      <Image source={require("../assets/images/ForgetPass.jpeg")} style={styles.image} />
      <TextInput
        placeholder="Enter your email"
        style={styles.input}
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
      />
      <TouchableOpacity style={styles.button} onPress={handleRequestReset} disabled={loading}>
        {loading ? (
           <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
        ) : (
          <Text style={styles.buttonText}>Send Reset Code</Text>
        )}
      </TouchableOpacity>

      <Stepper currentStep={1} totalSteps={3}></Stepper>
    </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollContainer: {
    flexGrow: 1,
    backgroundColor: Colors.light.backGroundColor,
  },
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: Colors.light.backGroundColor,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
  },
  image: {
    width: 250,
    height: 250,
    marginBottom: 20,
    borderRadius: 20,
  },
  input: {
    width: "100%",
    borderWidth: 1,
    borderColor: "#000",
    padding: 10,
    borderRadius: 10,
    marginBottom: 15,
  },
  button: {
    width: "100%",
    padding: 15,
    backgroundColor: Colors.light.buttonColor,
    borderRadius: 10,
    alignItems: "center",
  },
  buttonText: {
    color: "white",
    fontSize: 16,
    fontWeight: "bold",
  },
  resendContainer: {
    marginTop: 10,
    alignItems: "center",
  },
  resendText: {
    fontSize: 14,
    color: "black",
    textDecorationLine: "underline",
  },
});

export default ForgotPasswordScreen;
