import 'package:flutter/material.dart';
import '../models/analysis.dart';
import 'form_screen.dart';

class AddScreen extends StatelessWidget {
  final Future<void> Function(AnalysisResult, Map<String, dynamic>) onAnalysisDone;
  const AddScreen({super.key, required this.onAnalysisDone});

  @override
  Widget build(BuildContext context) {
    // Reuse existing form to input body metrics and upload lab results.
    return FormScreen(onAnalysisDone: onAnalysisDone);
  }
}

