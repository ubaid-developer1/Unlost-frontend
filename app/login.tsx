import React, { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, useColorScheme, ScrollView } from "react-native";
import { Link, Redirect, router } from "expo-router";
import Icon from "react-native-vector-icons/Feather";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Feather } from "@expo/vector-icons";
import GoogleSignInButton from "@/components/ui/GoogleButton";
import withAuthCheck from "@/components/ui/AuthChecker";
import { environment } from "@/components/ui/environment";
import * as WebBrowser from 'expo-web-browser'
import { Colors } from "@/constants/Colors";
import * as Linking from 'expo-linking'
import { SignedIn, useAuth, useOAuth, useUser } from "@clerk/clerk-expo";
import { getUserProfile } from "@/components/ui/UserProfile";

export const useWarmUpBrowser = () => {

  React.useEffect(() => {
    // Warm up the android browser to improve UX
    // https://docs.expo.dev/guides/authentication/#improving-user-experience
    void WebBrowser.warmUpAsync()
    return () => {
      void WebBrowser.coolDownAsync()
    }
  }, [])
}

WebBrowser.maybeCompleteAuthSession()

const Login = () => {
  useWarmUpBrowser()
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [loading, setLoading] = useState(false); // State for handling loading indicator
  const [message, setMessage] = useState("");
  const { startOAuthFlow } = useOAuth({ strategy: 'oauth_google' })
  const { user } = useUser();
  const { isSignedIn, signOut } = useAuth();



  const colorScheme = useColorScheme()
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

  const [GoogleLoading, setGoogleLoading] = useState(false)

  const googlebuttonHandler = useCallback(async () => {
    setGoogleLoading(true)
    try {
      const { createdSessionId, signIn, signUp, setActive } = await startOAuthFlow({
        redirectUrl: Linking.createURL('/login', { scheme: 'myapp' }),
      })

      // If sign in was successful, set the active session
      if (createdSessionId) {
        setActive!({ session: createdSessionId })
        if (user) {
          console.log("inv")
          const userName = user.username || `${user.firstName}${user.lastName}001`
          await sendGoogleAuthToBackend(userName, user.emailAddresses[0].emailAddress, user.imageUrl)
        }
      } else {
        console.log()
        // Use signIn or signUp returned from startOAuthFlow
        // for next steps, such as MFA
        setGoogleLoading(false)
        setMessage("Something went wrong, please try again.");
      }
    } catch (err) {
      // See https://clerk.com/docs/custom-flows/error-handling
      // for more info on error handling
      setGoogleLoading(false)
      setMessage("Something went wrong, please try again.");
      console.error(JSON.stringify(err, null, 2))
    }
  }, [])

  const sendGoogleAuthToBackend = async (username: string, email: string, profile: string) => {
    const userData = { username, email, profile };
    setGoogleLoading(true);

    try {
      const response = await fetch(`${environment.development}/user/authWithGoogle`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(userData),
      });

      const data = await response.json();

      if (response.ok && data.token) {
        await AsyncStorage.setItem("unlost_user_data", JSON.stringify(data));
        router.replace("/");
      } else {
        setMessage(data.message || "Authentication failed.");
      }
    } catch (error) {
      setMessage("Something went wrong, please try again.");
    } finally {
      setGoogleLoading(false);
    }
  };


  return (

    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <View style={styles.container}>
        <View style={styles.headingContainer}>
          <Text style={styles.heading}>UN-LOST</Text>
        </View>
        <Text
          style={{
            textAlign: "center",
            color: "gray",
            marginBottom: 10,
            marginTop: 5,
            fontSize: 18,
          }}
        >
          Keep track of all your items and never forget where they are again
        </Text>

        <Feather
          style={{ marginTop: 10, marginBottom:40, fontWeight: "bold" }}
          name="search"
          size={45}
          color="black"
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

        <Text style={styles.signupText}>
          Don't remember your password?{" "}
          <Text style={styles.signupLink}>
            <Link href="/forgetpassword">Forget password</Link>
          </Text>
        </Text>

        <GoogleSignInButton
          Title="Login with Google"
          onPress={googlebuttonHandler}
          IsLoading={GoogleLoading}
        />

        <Text style={styles.signupText}>
          Don't have an account?{" "}
          <Text style={styles.signupLink}>
            <Link href="/register">Register</Link>
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
    textTransform: "uppercase",
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
