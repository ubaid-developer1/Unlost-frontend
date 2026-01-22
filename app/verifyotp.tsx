import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  useColorScheme,
} from "react-native";
import { OtpInput } from "react-native-otp-entry";
import { router, useLocalSearchParams } from "expo-router";
import { environment } from "@/components/ui/environment";
import Stepper from "@/components/ui/ProgressStepper";
import Toast from "react-native-toast-message";
import { Colors } from "@/constants/Colors";

const VerifyOtpScreen = () => {
  const { email } = useLocalSearchParams();
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false); // Track loading state for verifying OTP
  const [resendLoading, setResendLoading] = useState(false); // Track loading state for resend OTP

  // Handle OTP verification
  const colorScheme = useColorScheme()
  const handleVerifyCode = async () => {
    if (!code) {
      alert("Please enter the verification code.");
      return;
    }

    setLoading(true); // Show loader for OTP verification

    try {
      const response = await fetch(
        `${environment.development}/forget-password/verify-otp`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ email, code }),
        }
      );

      const data = await response.json();
      console.log(data);

      if (response.ok) {
        router.push(`/resetpassword?email=${email}`);
      } else {
        alert(data.message || "Error occurred, please try again.");
      }
    } catch (error) {
      alert("An error occurred while verifying the OTP. Please try again.");
    } finally {
      setLoading(false); // Hide loader after verification
    }
  };

  // Handle OTP resend
  const handleResendOtp = async () => {
    setResendLoading(true); // Show loader for OTP resend

    try {
      const response = await fetch(
        `${environment.development}/forget-password/request-reset`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ email }),
        }
      );

      const data = await response.json();
     
      if (response.ok) {
        Toast.show({
            type:"success",
            text1:"OTP Resend Successfully",
        })
      } else {
        alert(data.message || "Error occurred, please try again.");
      }
    } catch (error) {
      alert("An error occurred while resending the OTP. Please try again.");
    } finally {
      setResendLoading(false); // Hide loader after resend request
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Enter Verification Code</Text>
      <OtpInput numberOfDigits={6} focusColor="black" onTextChange={setCode} />
      
      {/* Resend OTP link */}
      <TouchableOpacity
        style={styles.resendContainer}
        onPress={handleResendOtp}
        disabled={resendLoading} // Disable button while loading
      >
        {resendLoading ? (
          <ActivityIndicator size="small" color="#000" />
        ) : (
          <Text style={styles.resendText}>Didn't receive the code? Resend Code</Text>
        )}
      </TouchableOpacity>

      {/* Verify OTP button */}
      <TouchableOpacity
        style={styles.button}
        onPress={handleVerifyCode}
        disabled={loading} // Disable button while loading
      >
        {loading ? (
           <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
        ) : (
          <Text style={styles.buttonText}>Verify</Text>
        )}
      </TouchableOpacity>

      <Stepper currentStep={2} totalSteps={3}></Stepper>

      <Toast></Toast>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    backgroundColor: Colors.light.backGroundColor,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
  },
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 15,
  },
  input: {
    width: "100%",
    borderWidth: 1,
    borderColor: "#000",
    padding: 10,
    borderRadius: 10,
    marginLeft: 10,
  },
  button: {
    width: "100%",
    padding: 15,
    backgroundColor: Colors.light.buttonColor,
    borderRadius: 10,
    alignItems: "center",
    marginTop: 20,
  },
  buttonText: {
    color: "white",
    fontSize: 16,
    fontWeight: "bold",
  },
  checkboxContainer: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 15,
  },
  checkboxLabel: {
    marginLeft: 10,
    fontSize: 14,
    color: "#000",
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

export default VerifyOtpScreen;
