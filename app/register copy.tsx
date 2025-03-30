import GoogleSignInButton from '@/components/ui/GoogleButton';
import { Link, router } from 'expo-router';
import React, { useCallback, useEffect, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, useColorScheme, ScrollView } from 'react-native';
import Icon from 'react-native-vector-icons/Feather';
import AsyncStorage from '@react-native-async-storage/async-storage';
import withAuthCheck from '@/components/ui/AuthChecker';
import { environment } from '@/components/ui/environment';
import { Colors } from '@/constants/Colors';
import * as Linking from 'expo-linking'
import { useUser, useAuth, useOAuth } from '@clerk/clerk-expo';
import * as WebBrowser from 'expo-web-browser'

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

const Register = () => {
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const { user } = useUser();
  const [GoogleLoading, setGoogleLoading] = useState(false)
  const {isSignedIn , signOut} = useAuth();
  const { startOAuthFlow } = useOAuth({ strategy: 'oauth_google' })


  const colorScheme = useColorScheme()

  // Yaha token ki validation
  //  ...
  // 

  useEffect(() => {
    if (isSignedIn && user) {
      sendGoogleAuthToBackend(
        user.firstName,
        user.emailAddresses[0].emailAddress,
        user.imageUrl
      ).then(()=>{

      }).catch(()=>{
        signOut()
      })
    }
  }, [user])

  const handleRegister = async () => {
    if (!email || !username || !password) {
      setMessage('Please fill in all fields');
      return;
    }

    setLoading(true);
    setMessage(''); // Clear previous messages

    try {
      const response = await fetch(`${environment.development}/user/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, username, password }),
      });

      const data = await response.json();
      if (response.ok) {
        await AsyncStorage.setItem("unlost_user_data", JSON.stringify(data));
        router.replace("/")
        setMessage("Registration successful! Redirecting...");
      } else {
        setMessage(data.message || 'Registration failed');
      }
    } catch (error) {
      setMessage('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  
  const googlebuttonHandler = useCallback(async () => {
    setGoogleLoading(true)
    try {
      const { createdSessionId, signIn, signUp, setActive } = await startOAuthFlow({
        redirectUrl: Linking.createURL('/register', { scheme: 'myapp' }),
      })

      // If sign in was successful, set the active session
      if (createdSessionId) {
        setActive!({ session: createdSessionId })
        if (user){
          const userName = user.username || `${user.firstName}${user.lastName}001`
          await sendGoogleAuthToBackend(userName, user.emailAddresses[0].emailAddress , user.imageUrl)
        }
      } else {
        // Use signIn or signUp returned from startOAuthFlow
        // for next steps, such as MFA
        setGoogleLoading(false)
        setMessage("Something went wrong, please try again.");
      }
    } catch (err) {
      setMessage("Something went wrong, please try again.");
      setGoogleLoading(false)
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
      <Text style={styles.heading}>Let’s Get Started</Text>

      {/* Username Input */}
      <View style={styles.inputContainer}>
        <Icon name="user" size={20} color="#000" style={styles.icon} />
        <TextInput
          placeholder="Username"
          style={styles.input}
          value={username}
          onChangeText={setUsername}
          keyboardType="default"
        />
      </View>

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
        <TouchableOpacity onPress={() => setPasswordVisible(!passwordVisible)} style={styles.eyeIcon}>
          <Icon name={passwordVisible ? "eye-off" : "eye"} size={20} color="#000" />
        </TouchableOpacity>
      </View>

      {/* Message Display */}
      {message ? <Text style={styles.message}>{message}</Text> : null}

      {/* Register Button */}
      <TouchableOpacity style={styles.button} onPress={handleRegister} disabled={loading}>
        {loading ? (
          <ActivityIndicator size="small" color={colorScheme === "dark" ? "#fff" : "#000"} />
        ) : (
          <Text style={styles.buttonText}>Register</Text>
        )}
      </TouchableOpacity>

      <GoogleSignInButton Title='Register with Google' onPress={googlebuttonHandler}
        IsLoading={GoogleLoading} />

      <Text style={styles.signupText}>
        Already have an account? <Text style={styles.signupLink}><Link href="/login">Login</Link></Text>
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
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: Colors.light.backGroundColor,
  },
  heading: {
    fontSize: 32,
    fontWeight: '600',
    color: '#000',
    marginBottom: 50,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    marginBottom: 15,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#000',
    paddingHorizontal: 10,
    height: 50,
  },
  icon: {
    marginRight: 10,
  },
  input: {
    flex: 1,
    fontSize: 16,
    color: '#000',
  },
  eyeIcon: {
    padding: 10,
  },
  button: {
    width: '100%',
    backgroundColor: Colors.light.buttonColor,
    borderRadius: 12,
    paddingVertical: 15,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
  },
  buttonText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '600',
  },
  signupText: {
    marginTop: 20,
    fontSize: 14,
    color: '#000',
  },
  signupLink: {
    color: '#000',
    fontWeight: '600',
  },
  message: {
    color: 'red',
    marginVertical: 10,
    fontSize: 14,
    fontWeight: 'bold',
  },
})

export default Register;