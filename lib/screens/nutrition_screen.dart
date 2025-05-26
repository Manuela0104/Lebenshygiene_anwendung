import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ernährung'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Ernährung Screen - Coming Soon'),
      ),
    );
  }
} 