import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/trend_point.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class TrendPage extends StatefulWidget {
  const TrendPage({super.key});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  int _selectedDays = 7;
  bool _isLoading = false;
  String _message = 'Trend data has not been loaded yet.';
  List<TrendPoint> _points = [];

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isLoading = true;
      _message = 'Loading trend data...';
    });

    try {
      final position = await LocationService.determinePosition();

      final points = await ApiService.fetchWaterQualityTrend(
        latitude: position.latitude,
        longitude: position.longitude,
        days: _selectedDays,
      );

      setState(() {
        _points = points;
        _message = 'Trend data loaded successfully.';
      });
    } catch (e) {
      setState(() {
        _points = [];
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeDays(int days) {
    if (_selectedDays == days) return;
    setState(() {
      _selectedDays = days;
    });
    _loadTrendData();
  }

  String _buildTrendSummary() {
    if (_points.length < 2) {
      return 'Not enough historical readings to describe a trend.';
    }

    final first = _points.first.value;
    final last = _points.last.value;
    final diff = last - first;

    if (diff.abs() < 0.1) {
      return 'The pH trend appears fairly stable over the selected period.';
    } else if (diff > 0) {
      return 'The pH trend shows a slight upward movement over the selected period.';
    } else {
      return 'The pH trend shows a slight downward movement over the selected period.';
    }
  }

  List<FlSpot> _buildSpots() {
    return List.generate(
      _points.length,
      (index) => FlSpot(index.toDouble(), _points[index].value),
    );
  }

  double _minY() {
    if (_points.isEmpty) return 0;
    final minValue = _points
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    return (minValue - 0.5).clamp(0, double.infinity);
  }

  double _maxY() {
    if (_points.isEmpty) return 14;
    final maxValue = _points
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 0.5).clamp(0, 14);
  }

  String _bottomTitle(double value) {
    if (_points.isEmpty) return '';
    final index = value.toInt();
    if (index < 0 || index >= _points.length) return '';

    final time = _points[index].time;

    if (_selectedDays == 1) {
      return '${time.hour}:00';
    }
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadTrendData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('24 Hours'),
                      selected: _selectedDays == 1,
                      onSelected: (_) => _changeDays(1),
                    ),
                    ChoiceChip(
                      label: const Text('7 Days'),
                      selected: _selectedDays == 7,
                      onSelected: (_) => _changeDays(7),
                    ),
                    ChoiceChip(
                      label: const Text('30 Days'),
                      selected: _selectedDays == 30,
                      onSelected: (_) => _changeDays(30),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _points.isEmpty
                      ? Center(
                          child: Text(_message, textAlign: TextAlign.center),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historical pH Trend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Showing the last $_selectedDays day(s)',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: LineChart(
                                LineChartData(
                                  minY: _minY(),
                                  maxY: _maxY(),
                                  gridData: const FlGridData(show: true),
                                  borderData: FlBorderData(show: true),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        interval: (_points.length / 4).clamp(
                                          1,
                                          double.infinity,
                                        ),
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              _bottomTitle(value),
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _buildSpots(),
                                      isCurved: true,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _buildTrendSummary(),
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
