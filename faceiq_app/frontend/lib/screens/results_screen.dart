// lib/screens/results_screen.dart  — updated to use OverviewScreen as entry point
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import 'overview_screen.dart';

/// ResultsScreen is now just a thin redirect to OverviewScreen.
/// Keep it so existing Navigator.push calls don't break.
class ResultsScreen extends StatelessWidget {
  final CombinedResult result;
  final Uint8List? frontalBytes;
  final Uint8List? profileBytes;

  const ResultsScreen({
    super.key,
    required this.result,
    this.frontalBytes,
    this.profileBytes,
  });

  @override
  Widget build(BuildContext context) {
    return OverviewScreen(
      result: result,
      frontalBytes: frontalBytes,
      profileBytes: profileBytes,
    );
  }
}
