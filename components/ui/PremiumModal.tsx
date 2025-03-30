import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Modal, Portal } from 'react-native-paper';

const PremiumModal = ({ visible, hideModal }) => {
  return (
    <Portal>
      <Modal visible={visible} onDismiss={hideModal} contentContainerStyle={styles.container}>
        <Text style={styles.header}>UN-LOST</Text>
        
        <Text style={styles.title}>
          Do You Need More Than 5 Locations to Save Your Items?
        </Text>

        <Text style={styles.description}>
          You’ve reached your limit of location fields but you can add more
        </Text>

        <Text style={styles.unlockText}>
          Unlock 10 More Customizable Locations!
        </Text>

        <Text style={styles.priceText}>One-Time Purchase Only $5</Text>

        <TouchableOpacity style={styles.upgradeButton}>
          <Text style={styles.upgradeButtonText}>Upgrade Now</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.notNowButton} onPress={hideModal}>
          <Text style={styles.notNowButtonText}>Not Now</Text>
        </TouchableOpacity>
      </Modal>
    </Portal>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'white',
    padding: 20,
    marginHorizontal: 20,
    borderRadius: 10,
    alignItems: 'center',
  },
  header: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
    color: '#0066cc',
    marginBottom: 10,
  },
  description: {
    fontSize: 14,
    textAlign: 'center',
    color: '#333',
    marginBottom: 15,
  },
  unlockText: {
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    color: '#0066cc',
    marginBottom: 10,
  },
  priceText: {
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'green',
    marginBottom: 20,
  },
  upgradeButton: {
    backgroundColor: 'green',
    paddingVertical: 10,
    paddingHorizontal: 30,
    borderRadius: 5,
    marginBottom: 10,
  },
  upgradeButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  notNowButton: {
    backgroundColor: '#0066cc',
    paddingVertical: 10,
    paddingHorizontal: 30,
    borderRadius: 5,
  },
  notNowButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
});

export default PremiumModal;
