import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final indicators = [
      {
        'name': 'Dissolved Oxygen',
        'value': '6.8 mg/L',
        'desc': 'Within an acceptable range',
      },
      {'name': 'pH', 'value': '7.2', 'desc': 'Acidity level is normal'},
      {
        'name': 'Turbidity',
        'value': 'Moderate',
        'desc': 'Water appears slightly cloudy',
      },
      {
        'name': 'Conductivity',
        'value': 'High',
        'desc': 'May indicate a higher level of dissolved substances',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Indicators')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: indicators.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = indicators[index];
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.water_drop_outlined,
                color: Colors.teal,
              ),
              title: Text(item['name']!),
              subtitle: Text(item['desc']!),
              trailing: Text(item['value']!),
            ),
          );
        },
      ),
    );
  }
}
