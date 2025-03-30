import React from 'react';
import { TouchableOpacity, Text, View, StyleSheet, ActivityIndicator } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { useColorScheme } from '@/hooks/useColorScheme'; // Assuming you have this hook

interface GoogleSignInButtonProps {
  onPress: () => void;
  Title: string;
  IsLoading: boolean;
}

const GoogleSignInButton: React.FC<GoogleSignInButtonProps> = ({ onPress, Title, IsLoading }) => {
  const colorScheme = useColorScheme(); // Get the current color scheme (light/dark)

  return (
    <TouchableOpacity style={styles.button} onPress={onPress}>
      {IsLoading ? (
        <ActivityIndicator size="small" color={colorScheme === 'dark' ? '#fff' : '#000'} />
      ) : (
        <>
          <View style={styles.iconContainer}>
            <Svg width={24} height={24} viewBox="0 0 48 48">
              <Path
                fill="#4285F4"
                d="M46.06 24.56c0-1.6-.14-3.13-.4-4.62H24v9.34h12.68c-.55 2.9-2.13 5.35-4.49 7l7.26 5.62c4.25-3.93 6.71-9.72 6.71-17.34z"
              />
              <Path
                fill="#34A853"
                d="M24 48c6.07 0 11.16-2 14.89-5.43l-7.26-5.62c-2 1.33-4.5 2.12-7.63 2.12-5.88 0-10.86-3.94-12.66-9.25l-7.37 5.7C8.84 43.27 15.88 48 24 48z"
              />
              <Path
                fill="#FBBC05"
                d="M11.34 29.82c-.5-1.33-.78-2.75-.78-4.22s.28-2.88.78-4.22l-7.37-5.7C2.86 18.28 2 21.06 2 24s.86 5.72 2.34 8.32l7-5.7z"
              />
              <Path
                fill="#EA4335"
                d="M24 9.5c3.42 0 6.5 1.18 8.94 3.5l6.61-6.5C35.16 2.4 30.07 0 24 0 15.88 0 8.84 4.73 5.21 11.18l7.37 5.7C13.14 11.43 18.12 9.5 24 9.5z"
              />
            </Svg>
          </View>
          <Text style={styles.text}>{Title}</Text>
        </>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    flexDirection: 'row',
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
    backgroundColor: '#fff',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  iconContainer: {
    marginRight: 10,
  },
  text: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#000',
  },
});

export default GoogleSignInButton;
