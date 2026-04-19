import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/story_generator.dart';

class StoryPage extends StatefulWidget {
  final String stationName;
  final String statusLabel;
  final String parameterName;
  final double? rawValue;
  final String unit;
  final String lastUpdated;
  final String trendSummary;

  const StoryPage({
    super.key,
    required this.stationName,
    required this.statusLabel,
    required this.parameterName,
    required this.rawValue,
    required this.unit,
    required this.lastUpdated,
    required this.trendSummary,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  bool _isSaving = false;

  Future<void> _saveRecord() async {
    if (widget.stationName == 'Unknown station' ||
        widget.statusLabel == 'Unknown' ||
        widget.rawValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid water quality record is available to save.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService.saveLog(
        stationName: widget.stationName,
        statusLabel: widget.statusLabel,
        parameterName: widget.parameterName,
        rawValue: widget.rawValue,
        unit: widget.unit,
        lastUpdated: widget.lastUpdated,
        trendSummary: widget.trendSummary,
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () async {
          throw Exception(
            'The record may already be visible in Logs. Cloud sync is taking longer than expected.',
          );
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record saved to Firestore.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = StoryGenerator.generate(
      statusLabel: widget.statusLabel,
      parameterName: widget.parameterName,
      rawValue: widget.rawValue,
      unit: widget.unit,
      trendSummary: widget.trendSummary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Story Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Station: ${widget.stationName}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: ${widget.lastUpdated}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Text(
                  story.body,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveRecord,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark_add_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save this record'),
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
