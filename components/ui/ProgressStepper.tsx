import React from "react";
import { View, Text, StyleSheet } from "react-native";

interface StepperProps {
  currentStep: number;
  totalSteps: number;
}

const Stepper: React.FC<StepperProps> = ({ currentStep, totalSteps }) => {
  return (
    <View style={styles.container}>
      {/* Progress Bar */}
      <View style={styles.progressBar}>
        <View
          style={[
            styles.progressFill,
            { width: `${(currentStep / totalSteps) * 100}%` },
          ]}
        />
      </View>

      {/* Step Indicator & Counter */}
      <View style={styles.stepInfo}>
        <Text style={styles.stepText}>{currentStep} of {totalSteps}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 20,
  },
  progressBar: {
    flex: 1,
    height: 8,
    borderRadius: 5,
    backgroundColor: "#D3D3D3",
  },
  progressFill: {
    height: "100%",
    borderRadius: 5,
    backgroundColor: "black",
  },
  stepInfo: {
    marginLeft: 10,
  },
  stepText: {
    fontSize: 14,
    fontWeight: "bold",
    color: "#1A2E40",
  },
});

export default Stepper;
