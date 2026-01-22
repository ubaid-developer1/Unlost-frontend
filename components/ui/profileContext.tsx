// BottomSheetContext.js
import React, { createContext, useState, useRef } from "react";

// Define the type for the context value
type BottomSheetContextType = {
  isVisible: boolean;
  openBottomSheet: () => void;
  closeBottomSheet: () => void;
  bottomSheetRef: React.RefObject<any> | null;
};

// Provide a default value for the context
export const BottomSheetContext = createContext<BottomSheetContextType>({
  isVisible: false,
  openBottomSheet: () => {}, // Default function (no-op)
  closeBottomSheet: () => {}, // Default function (no-op)
  bottomSheetRef: null, // Default ref
});

// Create the provider
export const BottomSheetProvider = ({ children }) => {
  const [isVisible, setIsVisible] = useState(false);
  const bottomSheetRef = useRef(null);

  // Open the bottom sheet
  const openBottomSheet = () => {
    setIsVisible(true);
    console.log("Invoked")
    bottomSheetRef.current?.expand();
  };

  // Close the bottom sheet
  const closeBottomSheet = () => {
    setIsVisible(false);
    bottomSheetRef.current?.close();
  };

  return (
    <BottomSheetContext.Provider
      value={{ isVisible, openBottomSheet, closeBottomSheet, bottomSheetRef }}
    >
      {children}
    </BottomSheetContext.Provider>
  );
};