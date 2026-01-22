import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  useColorScheme,
} from "react-native";
import Icon from "react-native-vector-icons/Feather";
import { router, useLocalSearchParams } from "expo-router";
import Toast from "react-native-toast-message";
import { environment } from "@/components/ui/environment";
import Stepper from "@/components/ui/ProgressStepper";
import { Colors } from "@/constants/Colors";
import Checkbox from "expo-checkbox"; // Importing Checkbox from expo-checkbox
import { ScrollView } from "react-native-gesture-handler";

const ResetPasswordScreen = () => {
  const { email } = useLocalSearchParams();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isSelected, setSelected] = useState(false); // Track show password state
  const [loading, setLoading] = useState(false); // Track loading state

   const colorScheme = useColorScheme()
  const handleResetPassword = async () => {
    if (password !== confirmPassword) {
      alert("Passwords do not match");
      return;
    }

    setLoading(true); // Start loader

    try {
      const response = await fetch(
        `${environment.development}/forget-password/reset-password`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ email, newPassword: password }),
        }
      );

      const data = await response.json();

      if (response.ok) {
        Toast.show({
          type: "success",
          text1: "Password Reset Successfully",
        });
        setTimeout(() => {
          router.replace("/login");
        }, 1200);
      } else {
        alert(data.message || "Something went wrong");
      }
    } catch (error) {
      alert("An error occurred while resetting the password. Please try again.");
    } finally {
      setLoading(false); // Stop loader
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
    <View style={styles.container}>
      <Text style={styles.title}>Create New Password</Text>

      {/* Password Input */}
      <View style={styles.inputContainer}>
        <Icon name="lock" size={20} color="#000" />
        <TextInput
          placeholder="Password"
          style={styles.input}
          secureTextEntry={!isSelected} // Toggle visibility based on checkbox
          onChangeText={setPassword}
        />
      </View>

      {/* Confirm Password Input */}
      <View style={styles.inputContainer}>
        <Icon name="lock" size={20} color="#000" />
        <TextInput
          placeholder="Confirm Password"
          style={styles.input}
          secureTextEntry={!isSelected} // Toggle visibility based on checkbox
          onChangeText={setConfirmPassword}
        />
      </View>

      {/* Show Password Checkbox */}
      <View style={styles.checkboxContainer}>
        <Checkbox
          value={isSelected}
          onValueChange={setSelected}
          color={isSelected ? Colors.light.buttonColor : undefined}
        />
        <Text style={styles.checkboxLabel}>Show Password</Text>
      </View>

      {/* Reset Password Button */}
      <TouchableOpacity
        style={styles.button}
        onPress={handleResetPassword}
        disabled={loading} // Disable button while loading
      >
        {loading ? (
           <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
        ) : (
          <Text style={styles.buttonText}>Reset Password</Text>
        )}
      </TouchableOpacity>

      {/* Toast Notification */}
      <Toast />

      {/* Stepper */}
      <Stepper currentStep={3} totalSteps={3} />
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
    justifyContent: 'center',
    backgroundColor: Colors.light.backGroundColor,
    paddingHorizontal: 20,
    paddingVertical: 30,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#000',
    textAlign: 'center',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#000',
    borderRadius: 10,
    paddingHorizontal: 10,
    height: 50,
    marginBottom: 15,
  },
  input: {
    flex: 1,
    fontSize: 16,
    color: '#000',
  },
  button: {
    width: '100%',
    paddingVertical: 15,
    backgroundColor: Colors.light.buttonColor,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 20,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  checkboxContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  checkboxLabel: {
    marginLeft: 10,
    fontSize: 14,
    color: '#000',
  },
});


export default ResetPasswordScreen;
