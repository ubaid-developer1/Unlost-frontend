import AsyncStorage from '@react-native-async-storage/async-storage';

interface UserProfile {
  username: string;
  email: string;
  profile?: string; // Optional profile picture
  token: string;
}

// Fetch the user profile from AsyncStorage
export const getUserProfile = async (): Promise<UserProfile | null> => {
  try {
    const userData = await AsyncStorage.getItem('unlost_user_data');
    if (userData) {
      return JSON.parse(userData);
    }
    return null; // If no user data found, return null
  } catch (error) {
    console.error('Error fetching user profile from AsyncStorage:', error);
    return null;
  }
};

// Update the user profile in AsyncStorage
export const updateProfile = async (
  updatedUsername: string,
  updatedEmail: string,
  updatedProfilePicture?: string // Optional, only update if provided
): Promise<UserProfile | null> => {
  try {
    const userProfile = await getUserProfile();

    if (userProfile) {
      // Update the user profile data
      const updatedProfile = {
        ...userProfile,
        username: updatedUsername || userProfile.username,
        email: updatedEmail || userProfile.email,
        profile: updatedProfilePicture || userProfile.profile,
      };

      // Save the updated user profile in AsyncStorage
      await AsyncStorage.setItem('unlost_user_data', JSON.stringify(updatedProfile));

      // Return the updated profile
      return updatedProfile;
    } else {
      console.error('User profile not found');
      return null;
    }
  } catch (error) {
    console.error('Error updating user profile in AsyncStorage:', error);
    return null;
  }
};
