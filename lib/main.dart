import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:payment_integration/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51Mx4TsSIU0CfsPunt5VuRK4Vl5RWVf1ALZZm1zwEtRkKcUJrT71sA6BkCmFjLmsBAQoFU7OjFU3Mmvvqjqh4KEAl00Flkt9KHY';
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
