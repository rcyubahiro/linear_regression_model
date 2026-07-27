import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaternalHealthApp());
}

class MaternalHealthApp extends StatelessWidget {
  const MaternalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maternal Health Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // IMPORTANT: replace with your deployed Render URL, e.g.
  // "https://your-service-name.onrender.com/predict"
  static const String apiUrl = "https://YOUR-RENDER-URL.onrender.com/predict";

  final _formKey = GlobalKey<FormState>();

  // One controller per input field, matching the API's Pydantic schema
  final _yearController = TextEditingController();
  final _skilledBirthController = TextEditingController();
  final _healthExpController = TextEditingController();
  final _physiciansController = TextEditingController();
  final _literacyController = TextEditingController();
  final _electricityController = TextEditingController();
  final _antenatalController = TextEditingController();

  bool _isLoading = false;
  String _resultText = "";
  bool _isError = false;

  // Field definitions: label, controller, min, max — mirrors the Pydantic
  // range constraints in the API so the user gets instant feedback instead
  // of waiting on a round trip for an out-of-range value.
  late final List<_FieldSpec> _fields = [
    _FieldSpec("Year", _yearController, 2000, 2035),
    _FieldSpec("Skilled birth attendance (%)", _skilledBirthController, 0, 100),
    _FieldSpec("Health expenditure per capita (US\$)", _healthExpController, 0, 2000),
    _FieldSpec("Physicians per 1,000 people", _physiciansController, 0, 10),
    _FieldSpec("Female literacy rate (%)", _literacyController, 0, 100),
    _FieldSpec("Access to electricity (%)", _electricityController, 0, 100),
    _FieldSpec("Antenatal care, 4+ visits (%)", _antenatalController, 0, 100),
  ];

  @override
  void dispose() {
    for (final f in _fields) {
      f.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _predict() async {
    setState(() {
      _resultText = "";
      _isError = false;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isError = true;
        _resultText = "Please fix the highlighted fields before predicting.";
      });
      return;
    }

    setState(() => _isLoading = true);

    final body = {
      "year": double.parse(_yearController.text).round(),
      "skilled_birth_attendance_pct": double.parse(_skilledBirthController.text),
      "health_expenditure_per_capita": double.parse(_healthExpController.text),
      "physicians_per_1000": double.parse(_physiciansController.text),
      "female_literacy_rate_pct": double.parse(_literacyController.text),
      "access_to_electricity_pct": double.parse(_electricityController.text),
      "antenatal_care_4visits_pct": double.parse(_antenatalController.text),
    };

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predicted = data["predicted_maternal_mortality_ratio"];
        setState(() {
          _isError = false;
          _resultText =
              "Predicted maternal mortality ratio:\n${(predicted as num).toStringAsFixed(1)} deaths per 100,000 live births";
        });
      } else {
        // Surfaces FastAPI/Pydantic validation errors (e.g. out-of-range
        // or missing values) directly to the user
        final data = jsonDecode(response.body);
        setState(() {
          _isError = true;
          _resultText = "Error (${response.statusCode}): ${data["detail"] ?? response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _resultText = "Network error: could not reach the API. $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maternal Health Predictor"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Enter the health-access indicators below to predict the "
                  "maternal mortality ratio for a country profile.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                for (final field in _fields) ...[
                  TextFormField(
                    controller: field.controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: field.label,
                      helperText: "Range: ${field.min} - ${field.max}",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Required";
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null) {
                        return "Enter a valid number";
                      }
                      if (parsed < field.min || parsed > field.max) {
                        return "Must be between ${field.min} and ${field.max}";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _predict,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Predict", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.teal.shade50,
                    border: Border.all(
                      color: _isError ? Colors.red.shade200 : Colors.teal.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _resultText.isEmpty ? "Prediction result will appear here." : _resultText,
                    style: TextStyle(
                      fontSize: 15,
                      color: _isError ? Colors.red.shade800 : Colors.teal.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldSpec {
  final String label;
  final TextEditingController controller;
  final num min;
  final num max;

  _FieldSpec(this.label, this.controller, this.min, this.max);
}
