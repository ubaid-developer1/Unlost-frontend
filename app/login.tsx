import React, { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, useColorScheme, ScrollView, Image } from "react-native";
import { Link, router } from "expo-router";
import Icon from "react-native-vector-icons/Feather";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { environment } from "@/components/ui/environment";
import { Colors } from "@/constants/Colors";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [loading, setLoading] = useState(false); // State for handling loading indicator
  const [message, setMessage] = useState("");

  const colorScheme = useColorScheme();

  const handleLogin = async () => {
    if (!email || !password) {
      setMessage("Please fill in all fields.");
      return;
    }

    setLoading(true); // Show loader when request is sent
    setMessage(""); // Clear previous messages

    try {
      const response = await fetch(`${environment.development}/user/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: email,
          password: password,
        }),
      });
      const data = await response.json();
      if (data.token) {
        await AsyncStorage.setItem("unlost_user_data", JSON.stringify(data));
        router.replace("/")
      } else {
        setMessage(data.message); // Show error message from response
      }
    } catch (error) {
      setMessage("Something went wrong, please try again.");
    } finally {
      setLoading(false); // Hide loader after request completion
    }
  };


  return (

    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <View style={styles.container}>
        <View style={styles.headingContainer}>
          <Text style={styles.heading}>Un-Lost</Text>
        </View>
        <Text
          style={{
            textAlign: "center",
            color: "black",
            marginBottom: 10,
            marginTop: 5,
            fontSize: 18,
          }}
        >
          Keep track of all your items and never forget where they are again
        </Text>

        <Image
          source={require('../assets/images/splash-icon.png')} // ya URI se bhi ho sakta hai
          style={{ width: 65, height: 65, marginTop: 10, marginBottom: 40 }}
        />

        {/* Email Input */}
        <View style={styles.inputContainer}>
          <Icon name="mail" size={20} color="#000" style={styles.icon} />
          <TextInput
            placeholder="Email"
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
          />
        </View>

        {/* Password Input */}
        <View style={styles.inputContainer}>
          <Icon name="lock" size={20} color="#000" style={styles.icon} />
          <TextInput
            placeholder="Password"
            style={styles.input}
            value={password}
            onChangeText={setPassword}
            secureTextEntry={!passwordVisible}
          />
          <TouchableOpacity
            onPress={() => setPasswordVisible(!passwordVisible)}
            style={styles.eyeIcon}
          >
            <Icon name={passwordVisible ? "eye-off" : "eye"} size={20} color="#000" />
          </TouchableOpacity>
        </View>

        {/* Message Display */}
        {message ? <Text style={styles.message}>{message}</Text> : null}

        {/* Login Button */}
        <TouchableOpacity style={styles.button} onPress={handleLogin}>
          {loading ? (
            <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
          ) : (
            <Text style={styles.buttonText}>Login</Text>
          )}
        </TouchableOpacity>

        <Text style={styles.info}>
          Info is case sensitive
        </Text>

        <Text style={styles.signupText}>
          Don't have an account?{" "}
          <Text style={styles.signupLink}>
            <Link href="/register" style={{ color: Colors.light.buttonColor }}>Register Here</Link>
          </Text>
        </Text>
        <Text style={styles.signupText}>
          Click Here for{" "}
          <Text style={styles.signupLink}>
            <Link href="/forgetpassword" style={{ color: Colors.light.buttonColor }}>Lost Password</Link>
          </Text>
        </Text>
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
    padding: 20,
    backgroundColor: Colors.light.backGroundColor,
  },
  heading: {
    fontSize: 50,
    fontWeight: "bold",
    color: "#fff",
    textAlign: "center",
    letterSpacing: 5,
    fontFamily: "Poppins-Bold",
    textShadowColor: "rgba(0, 0, 0, 0.2)",
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 3,
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
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    width: "100%",
    marginBottom: 15,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#000",
  },
  icon: {
    paddingLeft: 10,
  },
  input: {
    width: "85%",
    paddingLeft: 10,
    height: 50,
    fontSize: 16,
    color: "#000",
  },
  eyeIcon: {
    position: "absolute",
    right: 10,
    padding: 10,
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
  signupText: {
    marginTop: 20,
    fontSize: 14,
    color: "#000",
    textAlign:"center"
  },
  info: {
    marginTop: 10,
    fontSize: 16,
    color: "#000",
    fontWeight: "500",
  },
  signupLink: {
    color: "#000",
    fontWeight: "600",
  },
  message: {
    color: "red",
    marginVertical: 10,
    fontSize: 14,
    fontWeight: "bold",
  },
});


export default Login;
