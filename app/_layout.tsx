import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider,
} from "@react-navigation/native";
import { useFonts } from "expo-font";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect } from "react";
import "react-native-reanimated";

import { useColorScheme } from "@/hooks/useColorScheme";
import { Alert, View, ActivityIndicator } from "react-native"; // Import ActivityIndicator
import HeaderWithMenu from "@/components/ui/ProfileMenu";
import * as Notifications from "expo-notifications";
import { BottomSheetProvider } from "@/components/ui/profileContext";
import { environment } from "@/components/ui/environment";
import { PaperProvider } from "react-native-paper";

export default function RootLayout() {
  const colorScheme = useColorScheme();

  // Load fonts using the expo-font hook
  const [loaded] = useFonts({
    SpaceMono: require("../assets/fonts/SpaceMono-Regular.ttf"),
  });

  // Hide splash screen once fonts are loaded
  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  // Request notification permissions on mount
  useEffect(() => {
    const requestPermissions = async () => {
      const { status } = await Notifications.requestPermissionsAsync();
      if (status !== "granted") {
        Alert.alert("Permission required", "Enable notifications in settings.");
      }
    };
    requestPermissions();
  }, []);

  // Show a loading spinner if fonts are not loaded yet
  if (!loaded) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator
          size="large"
          color={colorScheme === "dark" ? "#ffffff" : "#000000"}
        />
      </View>
    );
  }

  return (
    <ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
      <PaperProvider>


        <BottomSheetProvider>
          <Stack
            screenOptions={{
              headerStyle: {
                backgroundColor: colorScheme === "dark" ? "#333" : "#fff", // Dark or light background for header
              },
              headerTintColor: colorScheme === "dark" ? "#fff" : "#000", // Set header text color to white in dark mode, black in light mode
              headerTitleStyle: {
                fontWeight: "bold", // Optional: Make header text bold
              },
            }}
          >
            <Stack.Screen name="index" options={{ headerShown: false }} />
            <Stack.Screen
              name="home"
              options={{
                title: "",
                headerLeft: () => <HeaderWithMenu />,
              }}
            />
            <Stack.Screen name="login" options={{ headerShown: false }} />
            <Stack.Screen name="register" options={{ headerShown: false }} />
            <Stack.Screen
              name="singleItem"
              options={{ headerTitle: "Item Information" }}
            />
            <Stack.Screen
              name="saveItem"
              options={{ headerShown: false }}
            />
            <Stack.Screen

              name="editItem"
              options={{ headerShown: false }}
            />
            <Stack.Screen
              name="editlocation"
              options={{ headerShown: false }}
            />
            <Stack.Screen
              name="forgetpassword"
              options={{ headerShown: false }}
            />
            <Stack.Screen
              name="resetpassword"
              options={{ headerTitle: "Reset Password" }}
            />
            <Stack.Screen
              name="verifyotp"
              options={{ headerTitle: "Verify OTP" }}
            />
          </Stack>

          <StatusBar style="auto" />
        </BottomSheetProvider>
      </PaperProvider>
    </ThemeProvider>
  );
}
