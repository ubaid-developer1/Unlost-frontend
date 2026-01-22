import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:unstop/bloc/auth_bloc.dart';
import 'package:unstop/bloc/auth_event.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:unstop/widgets/pop_up.dart';


Future<void> handleStripePayment({
  required BuildContext context,
  required String firestoreField, // 'itemSubscribed' or 'locationSubscribed'
}) async {
  try {
    // 1. Fetch Payment Intent from your backend
    final response = await fetchPaymentIntentClientSecret(); // must return { clientSecret: ... }
    final clientSecret = response['clientSecret'];

    // 2. Initialize Payment Sheet with CARD as default method
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'UN-LOST',
        style: ThemeMode.light,
        // ✳️ Make sure only Card method is available (by setting this on Stripe Dashboard).
      ),
    );

    // 3. Present the payment sheet
    await Stripe.instance.presentPaymentSheet();

    // 4. On success, update Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (firestoreField == 'itemSubscribed') {
      final doc = await userRef.get();
      final currentUpgrades = doc.data()?['itemUpgrades'] ?? 0;
      final newLimit = 25 * (currentUpgrades + 2); // Base 25, then +25 per upgrade

      await userRef.update({
        'itemSubscribed': true,
        'itemUpgrades': currentUpgrades + 1,
        'itemLimit': newLimit,
      });

      context.read<AuthBloc>().add(
        LoggedIn(user.uid, user.email!, itemSubscribed: true),
      );
    } else if (firestoreField == 'locationSubscribed') {
      await userRef.update({
        'locationSubscribed': true,
      });

      context.read<AuthBloc>().add(
        LoggedIn(user.uid, user.email!, locationSubscribed: true),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! ✅')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } catch (e) {
    debugPrint('❌ Stripe payment error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }
}
