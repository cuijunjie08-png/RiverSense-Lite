import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Logs'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.streamLogs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load logs: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No saved records yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final stationName = (data['stationName'] ?? 'Unknown station')
                  .toString();
              final statusLabel = (data['statusLabel'] ?? 'Unknown').toString();
              final parameterName = (data['parameterName'] ?? 'Reading')
                  .toString();
              final rawValue = data['rawValue'];
              final unit = (data['unit'] ?? '').toString();
              final lastUpdated = (data['lastUpdated'] ?? 'Unknown time')
                  .toString();
              final trendSummary = (data['trendSummary'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.bookmark_outline,
                    color: Colors.teal,
                  ),
                  title: Text(stationName),
                  subtitle: Text(
                    'Status: $statusLabel\n'
                    '$parameterName: ${rawValue ?? 'N/A'} $unit\n'
                    'Updated: $lastUpdated\n'
                    '$trendSummary',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
