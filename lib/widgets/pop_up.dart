import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide ApplePayButtonStyle, ApplePayButtonType;
import 'package:unstop/bloc/auth_bloc.dart';
import 'package:unstop/bloc/auth_event.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/main.dart';
import 'package:unstop/screens/auth/login_screen.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:unstop/widgets/customButton.dart';
import 'dart:io';
import 'package:unstop/widgets/payment_config.dart';
import 'package:pay/pay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unstop/widgets/stripe_payment.dart';

String os = Platform.operatingSystem;

Future<Map<String, dynamic>> fetchPaymentIntentClientSecret() async {
  final response = await http.post(
    Uri.parse(
      'https://unlost-backend.vercel.app/api/create-payment-intent',
    ),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'amount': 1000, // 10.00 USD
      'currency': 'usd',
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch clientSecret');
  }

  return json.decode(response.body);
}
Future<void> handleAppleOrGooglePayResult({
  required Map<String, dynamic> result,
  required String firestoreField,
}) async {
  try {
    debugPrint('🟢 Payment Result: $result');

    final response = await fetchPaymentIntentClientSecret();
    final clientSecret = response['clientSecret'];
    debugPrint('✅ Got clientSecret: $clientSecret');

    final token = result['paymentMethodData']['tokenizationData']['token'];
    final tokenJson = Map<String, dynamic>.from(json.decode(token));

    final params = PaymentMethodParams.cardFromToken(
      paymentMethodData: PaymentMethodDataCardFromToken(token: tokenJson['id']),
    );

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: params,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        firestoreField: true,
      });

      navigatorKey.currentContext!.read<AuthBloc>().add(
        LoggedIn(
          user.uid,
          user.email!,
          itemSubscribed: firestoreField == 'itemSubscribed',
          locationSubscribed: firestoreField == 'locationSubscribed',
        ),
      );
    }

    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Upgrade Successful! ✅')),
    );

    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  } catch (e, stack) {
    debugPrint('❌ Payment error: $e\n$stack');
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Payment failed. Try again.')),
    );
  }
}
var applePayButton = ApplePayButton(
  paymentConfiguration: PaymentConfiguration.fromJsonString(defaultApplePay),
  paymentItems: const [
    PaymentItem(label: 'UN-LOST Subscription', amount: '10.00', status: PaymentItemStatus.final_price),
  ],
  style: ApplePayButtonStyle.black,
  width: double.infinity,
  height: 50,
  type: ApplePayButtonType.buy,
  margin: const EdgeInsets.only(top: 15.0),
  onPaymentResult: (result) async => await handleAppleOrGooglePayResult(
    result: result,
    firestoreField: 'itemSubscribed',
  ),
  loadingIndicator: const Center(child: CircularProgressIndicator()),
);
var googlePayButton = GooglePayButton(
  paymentConfiguration: PaymentConfiguration.fromJsonString(defaultGooglePay),
  paymentItems: const [
    PaymentItem(
      label: 'UN-LOST Subscription',
      amount: '10.00',
      status: PaymentItemStatus.final_price,
    ),
  ],
  type: GooglePayButtonType.pay,
  margin: const EdgeInsets.only(top: 15.0),
 onPaymentResult: (paymentResult) async {
  debugPrint('Google Pay Payment Result: $paymentResult');

  // final clientSecret = await fetchPaymentIntentClientSecret(); // your server must return a valid PaymentIntent with amount and currency
final response = await fetchPaymentIntentClientSecret();
final clientSecret = response['clientSecret'];
  debugPrint('✅ Got clientSecret: $clientSecret');

  if (clientSecret == null) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
    return;
  }

  try {
    final token = paymentResult['paymentMethodData']['tokenizationData']['token'];
    final tokenJson = Map<String, dynamic>.from(json.decode(token));

    final params = PaymentMethodParams.cardFromToken(
     paymentMethodData: PaymentMethodDataCardFromToken(token: tokenJson['id']),
    );
    

    await Stripe.instance.confirmPayment(
    paymentIntentClientSecret: clientSecret.toString(),
      data: params, 
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'itemSubscribed': true,
      });

      navigatorKey.currentContext!.read<AuthBloc>().add(
        LoggedIn(user.uid, user.email!, itemSubscribed: true),
      );
    }

    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Upgrade Successful! ✅')),
    );

    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  } catch (e) {
    debugPrint('Error during payment: $e');
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Payment failed. Try again.')),
    );
  }
 },

  loadingIndicator: const Center(child: CircularProgressIndicator()),
);

// Apple Pay – Location Upgrade
var applePayButtonLocation = ApplePayButton(
  paymentConfiguration: PaymentConfiguration.fromJsonString(defaultApplePay),
  paymentItems: const [
    PaymentItem(label: 'UN-LOST Subscription', amount: '10.00', status: PaymentItemStatus.final_price),
  ],
  style: ApplePayButtonStyle.black,
  width: double.infinity,
  height: 50,
  type: ApplePayButtonType.buy,
  margin: const EdgeInsets.only(top: 15.0),
  onPaymentResult: (result) async => await handleAppleOrGooglePayResult(
    result: result,
    firestoreField: 'locationSubscribed',
  ),
  loadingIndicator: const Center(child: CircularProgressIndicator()),
);
var googlePayButtonLocation = GooglePayButton(
  paymentConfiguration: PaymentConfiguration.fromJsonString(defaultGooglePay),
  paymentItems: const [
    PaymentItem(
      label: 'UN-LOST Subscription',
      amount: '10.00',
      status: PaymentItemStatus.final_price,
    ),
  ],
  type: GooglePayButtonType.pay,
  margin: const EdgeInsets.only(top: 15.0),
 onPaymentResult: (paymentResult) async {
  debugPrint('🟡 Location Payment Result: $paymentResult');

  try {
    // 1. Fetch client secret from your backend
    final clientSecretResponse = await fetchPaymentIntentClientSecret();
    final clientSecret = clientSecretResponse['clientSecret'];
    debugPrint('🟢 Fetched clientSecret: $clientSecret');

    // 2. Extract token from Google/Apple Pay result
    final token = paymentResult['paymentMethodData']['tokenizationData']['token'];
    final tokenJson = Map<String, dynamic>.from(json.decode(token));

    // 3. Create payment method using token
    final paymentMethod = await Stripe.instance.createPaymentMethod(
      params: PaymentMethodParams.cardFromToken(
        paymentMethodData: PaymentMethodDataCardFromToken(token: tokenJson['id']),
      ),
    );

    // 4. Confirm the payment
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: PaymentMethodParams.cardFromMethodId(
        paymentMethodData: PaymentMethodDataCardFromMethod(
          paymentMethodId: paymentMethod.id,
        ),
      ),
    );

    debugPrint('✅ Location payment confirmed');

    // 5. Update Firestore and state
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'locationSubscribed': true,
      });

      navigatorKey.currentContext!.read<AuthBloc>().add(
        LoggedIn(user.uid, user.email!, locationSubscribed: true),
      );
    }

    // 6. Show success message and navigate
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Location upgrade successful! ✅')),
    );

    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  } catch (e, stack) {
    debugPrint('❌ Location payment failed: $e\n$stack');
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Location upgrade failed. Please try again.')),
    );
  }
},

  loadingIndicator: const Center(child: CircularProgressIndicator()),
);

void showUpgradeDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final itemUpgrades = userDoc.data()?['itemUpgrades'] ?? 0;
  final nextLimit =
      50 *
      (itemUpgrades +
          2); // +1 to get next limit, +1 since first upgrade starts from 0
  final cost = '10.00'; // Fixed cost per upgrade

  final Widget payButton =
      Platform.isIOS
          ? ApplePayButton(
            paymentConfiguration: PaymentConfiguration.fromJsonString(
              defaultApplePay,
            ),
            paymentItems: [
              PaymentItem(
                label: 'UN-LOST Upgrade',
                amount: cost,
                status: PaymentItemStatus.final_price,
              ),
            ],
            style: ApplePayButtonStyle.black, 
            width: double.infinity,
            height: 50,
            type: ApplePayButtonType.buy,
            margin: const EdgeInsets.only(top: 15.0),
            onPaymentResult: (result) => handleUpgradePayment(context,result),
            loadingIndicator: const Center(child: CircularProgressIndicator()),
          )
          : GooglePayButton(
            paymentConfiguration: PaymentConfiguration.fromJsonString(
              defaultGooglePay,
            ),
            paymentItems: [
              PaymentItem(
                label: 'UN-LOST Upgrade',
                amount: cost,
                status: PaymentItemStatus.final_price,
              ),
            ],
            type: GooglePayButtonType.pay,
            margin: const EdgeInsets.only(top: 15.0),
            onPaymentResult: (result) => handleUpgradePayment(context,result),
            loadingIndicator: const Center(child: CircularProgressIndicator()),
          );

  showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'UN-LOST',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Do You Have More Items To Save?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorConstants.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "If You're Running Low On Space To Save Your Items, You Can Add More",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Increase Your Limit To Save 25 More Items!',
                    // 'Increase Your Limit To Save $nextLimit Items!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: ColorConstants.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    textAlign: TextAlign.center,
                    'One-Time Purchase\nOnly \$10',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  customButton(
                    label: 'Upgrade Now',
                    color: Colors.green,
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      // showUpgradeSheet(context, payButton: payButton);

                      showUpgradeSheet(context, firestoreField: 'itemSubscribed');
                    },
                  ),
                  const SizedBox(height: 12),
                  customButton(
                    label: 'Not Now',
                    color: ColorConstants.blue,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
void showUpgradeSheet(BuildContext context, {required String firestoreField}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pay with Card'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => handleStripePayment(
              context: context,
              firestoreField: firestoreField,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Proceed to Pay',style: TextStyle(color: Colors.white),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

// void showUpgradeSheet(BuildContext context, {required Widget payButton}) {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder:
//         (_) => Padding(
//           padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 20),
//               payButton,
//               const SizedBox(height: 12),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   'Not Now',
//                   style: TextStyle(
//                     color: Colors.blueAccent,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//   );
// }



Future<void> handleUpgradePayment(BuildContext context, Map<String, dynamic> paymentResult) async {
  try {
    debugPrint('🟡 handleUpgradePayment called');

    final clientSecretResponse = await fetchPaymentIntentClientSecret();
    final clientSecret = clientSecretResponse['clientSecret'];
    debugPrint('🟢 Fetched clientSecret: $clientSecret');

    // 🔑 Extract token from Google Pay result
    final token = paymentResult['paymentMethodData']['tokenizationData']['token'];
    final tokenJson = Map<String, dynamic>.from(jsonDecode(token));
    final tokenId = tokenJson['id'];
    debugPrint('🔑 Token ID: $tokenId');

    // ✅ Create params using tokenized card
    final params = PaymentMethodParams.cardFromToken(
      paymentMethodData: PaymentMethodDataCardFromToken(token: tokenId),
    );

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: params,
    );

    debugPrint('✅ Payment confirmed');

    // Upgrade user logic
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final currentUpgrades = doc.data()?['itemUpgrades'] ?? 0;
    final newLimit = 50 * (currentUpgrades + 2);

    await userRef.update({
      'itemUpgrades': currentUpgrades + 1,
      'itemLimit': newLimit,
    });

    context.read<AuthBloc>().add(
      LoggedIn(user.uid, user.email!, itemSubscribed: true),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upgrade successful! ✅')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } catch (e, stack) {
    debugPrint('❌ Error in handleUpgradePayment: $e\n$stack');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }
}


Future<void> handleLocationUpgradePayment(BuildContext context, Map<String, dynamic> paymentResult) async {
  try {
    debugPrint('🟡 handleLocationUpgradePayment called');

    final clientSecretResponse = await fetchPaymentIntentClientSecret();
    final clientSecret = clientSecretResponse['clientSecret'];
    debugPrint('🟢 Fetched clientSecret: $clientSecret');

    final token = paymentResult['paymentMethodData']['tokenizationData']['token'];
    final tokenJson = Map<String, dynamic>.from(jsonDecode(token));
    final tokenId = tokenJson['id'];

    final params = PaymentMethodParams.cardFromToken(
      paymentMethodData: PaymentMethodDataCardFromToken(token: tokenId),
    );

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: params,
    );

    debugPrint('✅ Location payment confirmed');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'locationSubscribed': true,
    });

    context.read<AuthBloc>().add(
      LoggedIn(user.uid, user.email!, locationSubscribed: true),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location upgrade successful! ✅')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } catch (e, stack) {
    debugPrint('❌ Error in handleLocationUpgradePayment: $e\n$stack');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location upgrade failed. Please try again.')),
    );
  }
}

void showUpgradeDialogLocation(BuildContext context) {
 final payButton = Platform.isIOS
    ? ApplePayButton(
        paymentConfiguration: PaymentConfiguration.fromJsonString(defaultApplePay),
        paymentItems: const [
          PaymentItem(
            label: 'UN-LOST Location Upgrade',
            amount: '10.00',
            status: PaymentItemStatus.final_price,
          ),
        ],
        style: ApplePayButtonStyle.black,
        width: double.infinity,
        height: 50,
        type: ApplePayButtonType.buy,
        margin: const EdgeInsets.only(top: 15.0),
        onPaymentResult: (result) => handleLocationUpgradePayment(context, result),
        loadingIndicator: const Center(child: CircularProgressIndicator()),
      )
    : GooglePayButton(
        paymentConfiguration: PaymentConfiguration.fromJsonString(defaultGooglePay),
        paymentItems: const [
          PaymentItem(
            label: 'UN-LOST Location Upgrade',
            amount: '10.00',
            status: PaymentItemStatus.final_price,
          ),
        ],
        type: GooglePayButtonType.pay,
        margin: const EdgeInsets.only(top: 15.0),
        onPaymentResult: (result) => handleLocationUpgradePayment(context, result),
        loadingIndicator: const Center(child: CircularProgressIndicator()),
      );

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'UN-LOST',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(
                'Do You Need More Locations To Save Your Items?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstants.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You Can Increase Your Limit And Name Them Anything You Want",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                'Add 5 More\nCustomizable Locations!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                textAlign: TextAlign.center,
                'One-Time Purchase\nOnly \$10',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              customButton(
                label: 'Upgrade Now',
                color: Colors.green,
                onPressed: () => showUpgradeSheetLocation(
                  context,
                  // payButton: payButton,
                ),
              ),
              const SizedBox(height: 12),
              customButton(
                label: 'Not Now',
                color: ColorConstants.blue,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
void showUpgradeSheetLocation(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pay with Card',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => handleStripePayment(
              context: context,
              firestoreField: 'locationSubscribed',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Proceed to Pay',style: TextStyle(color: Colors.white),),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Now',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// void showUpgradeSheetLocation(
//   BuildContext context, {
//   required Widget payButton,
// }) {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) => Padding(
//       padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 20),
//           payButton,
//           const SizedBox(height: 12),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'Not Now',
//               style: TextStyle(
//                 color: Colors.blueAccent,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// void showProfileBottomSheet(BuildContext context) {
//  final user = FirebaseAuth.instance.currentUser;
//   final firestore = FirebaseFirestore.instance;

//   // Create controllers once, outside the builder
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.white,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return FutureBuilder<DocumentSnapshot>(
//         future: firestore.collection('users').doc(user?.uid).get(),
//         builder: (context, snapshot) {
//            if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Padding(
//               padding: EdgeInsets.all(32),
//               child: Center(child: CircularProgressIndicator()),
//             );
//           }

//           // ✅ Only set text once, after data is loaded
//           if (snapshot.hasData && snapshot.data!.exists) {
//             final userData = snapshot.data!.data() as Map<String, dynamic>;
//             nameController.text = userData['username'] ?? '';
//             emailController.text = userData['email'] ?? user?.email ?? '';
//           }

//           return Padding(
//             padding: EdgeInsets.only(
//               top: 20,
//               bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//               left: 20,
//               right: 20,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.person, size: 80, color: Colors.black),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'User Profile',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),

//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: nameController,
//                   style: TextStyle(color: Colors.black),

//                   decoration: const InputDecoration(
//                     labelText: 'Username',
//                     labelStyle: TextStyle(color: Colors.black),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                TextField(
//   controller: emailController,
//   readOnly: true,
//   enableInteractiveSelection: false, // disables long-press menu
//   style: const TextStyle(color: Colors.black),
//   decoration: const InputDecoration(
//     labelText: 'Email',
//     labelStyle: TextStyle(color: Colors.black),
//   ),
// )
// ,
//                 const SizedBox(height: 20),
//                 customButton(
//                   label: 'Save Changes',
//                   color: Colors.green,
//                   onPressed: () async {
//                     final username = nameController.text.trim();
//                     final email = emailController.text.trim();

//                     if (username.isNotEmpty && email.isNotEmpty) {
//                       await firestore.collection('users').doc(user!.uid).update(
//                         {'username': username, 'email': email},
//                       );
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Profile updated successfully!'),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//                 // ElevatedButton(
//                 //   onPressed:
//                 //   style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
//                 //   child: const Text('Save Changes'),
//                 // ),
//                 const SizedBox(height: 10),
//                 customButton(
//                   label: "Delete Account",
//                   color: Colors.black,
//                   onPressed: () async {
//                     final confirm = await showDialog<bool>(
//                       context: context,
//                       builder:
//                           (context) => AlertDialog(
//                             title: const Text("Confirm Account Deletion"),
//                             content: const Text(
//                               "Are you sure you want to permanently delete your account? This action cannot be undone.",
//                             ),
//                             actions: [
//                               TextButton(
//                                 child: const Text("Cancel"),
//                                 onPressed:
//                                     () => Navigator.of(context).pop(false),
//                               ),
//                               TextButton(
//                                 child: const Text(
//                                   "Delete",
//                                   style: TextStyle(color: Colors.red),
//                                 ),
//                                 onPressed:
//                                     () => Navigator.of(context).pop(true),
//                               ),
//                             ],
//                           ),
//                     );

//                     if (confirm == true) {
//                       final uid = user?.uid;

//                       try {
//                         // Delete Firestore user document
//                         if (uid != null) {
//                           await FirebaseFirestore.instance
//                               .collection('users')
//                               .doc(uid)
//                               .delete();
//                         }

//                         // Delete Firebase Auth user
//                         await user?.delete();

//                         // Logout and redirect
//                         context.read<AuthBloc>().add(LoggedOut());
//                         Navigator.of(context).pushAndRemoveUntil(
//                           MaterialPageRoute(
//                             builder: (context) => LoginScreen(),
//                           ),
//                           (route) => false,
//                         );

//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text("Account deleted successfully."),
//                           ),
//                         );
//                       } catch (e) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               "Failed to delete account: ${e.toString()}",
//                             ),
//                           ),
//                         );
//                       }
//                     }
//                   },
//                 ),

//                 const SizedBox(height: 10),
//                 customButton(
//                   label: "Logout",
//                   color: Colors.red,
//                   onPressed: () async {
//                     // await FirebaseAuth.instance.signOut();
//                     context.read<AuthBloc>().add(LoggedOut());
//                     //  context.read<AuthBloc>().add(LoggedIn(user.uid, user.email!));
//                     Navigator.of(context).pushAndRemoveUntil(
//                       MaterialPageRoute(builder: (context) => LoginScreen()),
//                       (Route<dynamic> route) => false,
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 35),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }

void showProfileBottomSheet(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  // Fetch the user data before showing the sheet
  final docSnapshot = await firestore.collection('users').doc(user?.uid).get();
  final userData = docSnapshot.data() ?? {};

  final nameController = TextEditingController(text: userData['username'] ?? '');
  final emailController = TextEditingController(text: userData['email'] ?? user?.email ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.black),
            const SizedBox(height: 10),
            const Text(
              'User Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              readOnly: true,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            customButton(
              label: 'Save Changes',
              color: Colors.green,
              onPressed: () async {
                final username = nameController.text.trim();
                final email = emailController.text.trim();

                if (username.isNotEmpty && email.isNotEmpty) {
                  await firestore.collection('users').doc(user!.uid).update({
                    'username': username,
                    'email': email,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            customButton(
              label: "Delete Account",
              color: Colors.black,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Account Deletion"),
                    content: const Text(
                      "Are you sure you want to permanently delete your account? This action cannot be undone.",
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final uid = user?.uid;
                  try {
                    if (uid != null) {
                      await firestore.collection('users').doc(uid).delete();
                    }
                    await user?.delete();
                    context.read<AuthBloc>().add(LoggedOut());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Account deleted successfully.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete account: ${e.toString()}")),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            customButton(
              label: "Logout",
              color: Colors.red,
              onPressed: () async {
                context.read<AuthBloc>().add(LoggedOut());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            const SizedBox(height: 35),
          ],
        ),
      );
    },
  );
}
