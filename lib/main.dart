import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConversionRate {
  final String currency;
  final double rate;

  ConversionRate({required this.currency, required this.rate});

  factory ConversionRate.fromJson(Map<String, double> json) {
    final currency = json.keys.first;
    final rate = json[currency]!;

    return ConversionRate(currency: currency, rate: rate);
  }
}

class CurrencyConverter {
  final String apiKey;
  final String url;

  CurrencyConverter({required this.apiKey, required this.url});

  Future<List<ConversionRate>> fetchConversionRates() async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final rates = jsonResponse['data'] as Map<String, dynamic>;
      final conversionRates = rates.entries.map((entry) {
        final currency = entry.key;
        final rate = entry.value.toDouble();
        return ConversionRate(currency: currency, rate: rate);
      }).toList();
      return conversionRates;
    } else {
      throw Exception(
          'Failed to fetch conversion rates. Error: ${response.statusCode}');
    }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CurrencyConverterPage(),
    );
  }
}

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({Key? key}) : super(key: key);

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  late Future<List<ConversionRate>> _conversionRates;
  ConversionRate? _selectedFromCurrency;
  ConversionRate? _selectedToCurrency;
  double _conversionRate = 0.0;
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final converter = CurrencyConverter(
      apiKey: 'apikey',
      url:
          'apiurl',
    );
    _conversionRates = converter.fetchConversionRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
      ),
      body: FutureBuilder<List<ConversionRate>>(
        future: _conversionRates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final conversionRates = snapshot.data!;
            final dropdownItems = conversionRates.map((rate) {
              return DropdownMenuItem<ConversionRate>(
                value: rate,
                child: Text(
                  rate.currency,
                  style: const TextStyle(
                    color: Colors.lightBlue,
                  ),
                ),
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ConversionRate>(
                          value: _selectedFromCurrency,
                          onChanged: (ConversionRate? newValue) {
                            setState(() {
                              _selectedFromCurrency = newValue;
                            });
                          },
                          items: dropdownItems,
                          decoration: const InputDecoration(
                            labelText: 'From Currency',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<ConversionRate>(
                          value: _selectedToCurrency,
                          onChanged: (ConversionRate? newValue) {
                            setState(() {
                              _selectedToCurrency = newValue;
                            });
                          },
                          items: dropdownItems,
                          decoration: const InputDecoration(
                            labelText: 'To Currency',
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedFromCurrency != null &&
                          _selectedToCurrency != null &&
                          _amountController.text.isNotEmpty) {
                        final double amount =
                            double.parse(_amountController.text);
                        final double fromRate = _selectedFromCurrency!.rate;
                        final double toRate = _selectedToCurrency!.rate;
                        final double conversionRate = toRate / fromRate;
                        final double convertedAmount = amount * conversionRate;

                        setState(() {
                          _conversionRate = conversionRate;
                        });

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Conversion Result'),
                              content: Text(
                                  '$amount ${_selectedFromCurrency!.currency} = $convertedAmount ${_selectedToCurrency!.currency}'),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: const Text('Convert'),
                  ),
                  if (_conversionRate != 0.0)
                    const Text(
                      '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
