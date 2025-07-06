
import 'package:flutter/material.dart';
import 'package:urbanquest_app/src/presentation/atoms/custom_button.dart';
import 'package:urbanquest_app/src/presentation/atoms/custom_text_field.dart';

class LoginOrganism extends StatelessWidget {
  const LoginOrganism({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomTextField(labelText: 'Email'),
        const SizedBox(height: 20),
        const CustomTextField(labelText: 'Password', obscureText: true),
        const SizedBox(height: 20),
        CustomButton(text: 'Login', onPressed: () {}),
      ],
    );
  }
}
