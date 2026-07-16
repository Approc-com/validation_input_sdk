import 'package:flutter/material.dart';
import 'package:validation_sdk/validation_sdk.dart';

/// Example — wire into your app main():
///
/// ```dart
/// final validation = ValidationSdk(
///   assetPath: 'assets/validation/validation.json',
///   remoteUrl: 'https://cdn.example.com/validation/validation.json',
/// );
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await validation.initialize();
///   validation.sync(localValidationFileVersion: validation.config.version); // fire-and-forget
///   runApp(MyApp(validation: validation));
/// }
/// ```
void main() {}

class ValidatedTextField extends StatelessWidget {
  const ValidatedTextField({
    super.key,
    required this.sdk,
    required this.screen,
    this.form,
    required this.fieldId,
    required this.controller,
    required this.allValues,
    this.tenantId,
    this.locale = 'en',
  });

  final ValidationSdk sdk;
  final String screen;
  final String? form;
  final String fieldId;
  final TextEditingController controller;
  final Map<String, dynamic> allValues;
  final String? tenantId;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: fieldId),
      validator: (_) {
        final result = sdk.validate(
          screen: screen,
          form: form,
          fieldId: fieldId,
          value: controller.text,
          allValues: allValues,
          tenantId: tenantId,
          locale: locale,
        );
        return result.isValid ? null : result.message;
      },
    );
  }
}

class LoginFormExample extends StatefulWidget {
  const LoginFormExample({super.key, required this.sdk, this.tenantId});

  final ValidationSdk sdk;
  final String? tenantId;

  @override
  State<LoginFormExample> createState() => _LoginFormExampleState();
}

class _LoginFormExampleState extends State<LoginFormExample> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> get _values => {
        'national_id': _id.text,
        'password': _password.text,
      };

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final errors = widget.sdk.validateScreen(
      screen: 'login',
      form: 'egyptian_form',
      values: _values,
      tenantId: widget.tenantId,
    );
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.values.first)),
      );
      return;
    }
    // proceed with API call — backend must still validate
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ValidatedTextField(
            sdk: widget.sdk,
            screen: 'login',
            form: 'egyptian_form',
            fieldId: 'national_id',
            controller: _id,
            allValues: _values,
            tenantId: widget.tenantId,
          ),
          ValidatedTextField(
            sdk: widget.sdk,
            screen: 'login',
            form: 'egyptian_form',
            fieldId: 'password',
            controller: _password,
            allValues: _values,
            tenantId: widget.tenantId,
          ),
          FilledButton(onPressed: _submit, child: const Text('Login')),
        ],
      ),
    );
  }
}
