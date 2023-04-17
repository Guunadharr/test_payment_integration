import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pay/pay.dart';
import 'package:payment_integration/constants.dart';
import 'package:http/http.dart' as http;
import 'package:payment_integration/payment_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //<--------------------- Stripe payment --------------------->
  Map<String, dynamic>? paymentIntent;

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent('20', 'INR');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntent!['client_secret'],
            style: ThemeMode.dark,
            merchantDisplayName: 'Dhanush'),
      );
      displayPaymentSheet();
    } catch (e) {
      print('exception' + e.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then(
            (value) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Paid Successful'),
              ),
            ),
          );
      // setState(() {
      //   paymentIntent = null;
      // });
    } on StripeException catch (e) {
      print(e.toString());
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Text('Cancelled'),
        ),
      );
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization':
                'Bearer sk_test_51Mx4TsSIU0CfsPunbnxWuYkQu58yIbDcjJOIuaaLcNNlLlUAP2CoLPN9uFw1B6DiT6kngHviDnO5A7hX6PaAE01k00bPG3CYJ3',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      return jsonDecode(response.body);
    } catch (e) {
      print('exception' + e.toString());
    }
  }

  calculateAmount(String amount) {
    final price = int.parse(amount) * 100;
    return price.toString();
  }

  //<--------------------- Google pay --------------------->
  late Future<bool> _userCanPay;

  Pay payClient = Pay.withAssets(['gpay.json']);

  final _paymentItems = [
    const PaymentItem(
      label: 'Item 1',
      amount: '50.00',
      status: PaymentItemStatus.final_price,
    )
  ];

  @override
  void initState() {
    _userCanPay = payClient.userCanPay(PayProvider.google_pay);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // google pay
    var googlepay = GooglePayButton(
      width: RawGooglePayButton.minimumButtonWidth,
      height: 50,
      paymentConfigurationAsset: 'gpay.json',
      // paymentConfiguration:
      //     PaymentConfiguration.fromJsonString(defaultGooglePay),
      paymentItems: _paymentItems,
      type: GooglePayButtonType.pay,
      margin: const EdgeInsets.only(top: 15.0),
      onPaymentResult: (result) {
        debugPrint('Payment Result: $result');
        _dialogBuilder(context, 'Success', 'Payment is successful');
      },
      loadingIndicator: const Center(
        child: CircularProgressIndicator(),
      ),
    );
    // Apple pay
    var applepay = ApplePayButton(
      height: 50,
      width: 100,
      margin: const EdgeInsets.only(top: 15),
      paymentConfigurationAsset: 'applepay.json',
      onPaymentResult: (result) {
        debugPrint('Payment Result: $result');
        _dialogBuilder(context, 'Success', 'Payment is successful');
      },
      paymentItems: _paymentItems,
      loadingIndicator: Center(child: CircularProgressIndicator()),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Home Page'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                // <--------------------------paypal------------------>
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => UsePaypal(
                          sandboxMode: true,
                          clientId: Constants.clientID,
                          secretKey: Constants.securityKey,
                          returnURL: Constants.returnURL,
                          cancelURL: Constants.cancelURL,
                          transactions: const [
                            {
                              "amount": {
                                "total": '10.12',
                                "currency": "USD",
                                "details": {
                                  "subtotal": '10.12',
                                  "shipping": '0',
                                  "shipping_discount": 0
                                }
                              },
                              "description":
                                  "The payment transaction description.",
                              // "payment_options": {
                              //   "allowed_payment_method":
                              //       "INSTANT_FUNDING_SOURCE"
                              // },
                              "item_list": {
                                "items": [
                                  {
                                    "name": "A demo product",
                                    "quantity": 1,
                                    "price": '10.12',
                                    "currency": "USD"
                                  }
                                ],

                                // shipping address is not required though
                                // "shipping_address": {
                                //   "recipient_name": "Jane Foster",
                                //   "line1": "Travis County",
                                //   "line2": "",
                                //   "city": "Austin",
                                //   "country_code": "US",
                                //   "postal_code": "73301",
                                //   "phone": "+00000000",
                                //   "state": "Texas"
                                // },
                              }
                            }
                          ],
                          note: "Contact us for any questions on your order.",
                          onSuccess: (Map params) async {
                            log(params.toString());
                            await _dialogBuilder(
                                context, 'Success', 'Payment is successful');
                          },
                          onError: (error) async {
                            print("onError: $error");
                            await _dialogBuilder(
                                context, 'Error', 'Payment is not successful');
                          },
                          onCancel: (params) async {
                            print('cancelled: $params');
                            await _dialogBuilder(
                                context, 'Cancel', 'Payment is cancelled');
                          },
                        ),
                      ),
                    );
                  },
                  child: Text('Pay with Paypal'),
                ),
                // <---------------------stripe payment---------------->
                ElevatedButton(
                  onPressed: () async {
                    await makePayment();
                  },
                  child: Text('Stripe Payment'),
                ),
                // <------------------Google pay button/ Apple pay button--------------->
                Platform.isAndroid ? googlepay : applepay,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(
      BuildContext context, String title, String content) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
