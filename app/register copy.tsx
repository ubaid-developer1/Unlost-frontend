import { Link, router } from 'expo-router';
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, useColorScheme, ScrollView } from 'react-native';
import Icon from 'react-native-vector-icons/Feather';
import AsyncStorage from '@react-native-async-storage/async-storage';
// import withAuthCheck from '@/components/ui/AuthChecker';
import { environment } from '@/components/ui/environment';
import { Colors } from '@/constants/Colors';

const Register = () => {
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');


  const colorScheme = useColorScheme()

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