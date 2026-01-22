import React, { useCallback, useEffect, useState } from 'react';
import { useFocusEffect, useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ActivityIndicator, View } from 'react-native';

// Higher-Order Component (HOC) to wrap public routes that require login check
const withAuthCheck = (WrappedComponent) => {
  const AuthCheck = (props) => {
    const [isChecking, setIsChecking] = useState(true);
    const router = useRouter();

    const checkLoginStatus = async (router, setIsChecking) => {
      const userData = await AsyncStorage.getItem('unlost_user_data');
      if (userData) {
        router.push('/home');
      } else {
        router.push('/login');
      }
      setIsChecking(false);
    };
    
    useFocusEffect(
      useCallback(() => {
        setIsChecking(true); // Start loading spinner
        checkLoginStatus(router, setIsChecking);
      }, [])
    )

    if (isChecking) {
      // Show a loading spinner while checking the login status
      return (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
          <ActivityIndicator size="large" color="#000" />
        </View>
      );
    }

    // If not checking anymore, render the wrapped component (though it shouldn't reach here)
    return <WrappedComponent {...props} />;
  };

  return AuthCheck;
};

export default withAuthCheck;
