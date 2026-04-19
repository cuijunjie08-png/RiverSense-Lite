import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/water_quality_data.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/quality_mapper.dart';
import 'detail_page.dart';
import 'story_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _position;
  String _locationMessage = 'Waiting for GPS access...';
  bool _isLoadingLocation = false;

  WaterQualityData? _waterQualityData;
  bool _isLoadingWaterData = false;
  String _waterDataMessage = 'Water quality data has not been loaded yet.';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationMessage = 'Getting your location...';
    });

    try {
      final position = await LocationService.determinePosition();

      setState(() {
        _position = position;
        _locationMessage =
            'Lat: ${position.latitude.toStringAsFixed(5)}, '
            'Lng: ${position.longitude.toStringAsFixed(5)}';
      });

      await _getWaterQuality(position);
    } catch (e) {
      setState(() {
        _locationMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getWaterQuality(Position position) async {
    setState(() {
      _isLoadingWaterData = true;
      _waterDataMessage = 'Loading water quality data...';
    });

    try {
      final data = await ApiService.fetchWaterQuality(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _waterQualityData = data;
        _waterDataMessage = 'Water quality data loaded successfully.';
      });
    } catch (e) {
      setState(() {
        _waterDataMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoadingWaterData = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _getLocation();
  }

  String _buildStoryTrendSummary() {
    if (_waterQualityData == null) {
      return 'No historical trend summary is currently available.';
    }

    final presentation = QualityMapper.mapPh(_waterQualityData!.rawValue);

    switch (presentation.label) {
      case 'Good':
        return 'Recent conditions appear relatively stable based on the currently available reading.';
      case 'Moderate':
        return 'Recent conditions may show slight fluctuation and deserve continued attention.';
      case 'Poor':
        return 'Recent conditions may be unstable or under greater environmental pressure.';
      default:
        return 'No clear trend summary is available at the moment.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RiverSense Lite'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _refreshAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nearest monitoring point',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _waterQualityData?.stationName ??
                        'Monitoring point: searching...',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _locationMessage,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_isLoadingLocation) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                  if (_position != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Accuracy: ${_position!.accuracy.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_isLoadingWaterData) {
      return Card(
        color: const Color(0xFFEAF7F3),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading water quality data...'),
            ],
          ),
        ),
      );
    }

    if (_waterQualityData == null) {
      return Card(
        color: const Color(0xFFEAF7F3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Current water quality status',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Unknown',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _waterDataMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final presentation = QualityMapper.mapPh(_waterQualityData!.rawValue);

    return Card(
      color: const Color(0xFFEAF7F3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Current water quality status',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            Icon(presentation.icon, size: 40, color: presentation.color),
            const SizedBox(height: 10),
            Text(
              presentation.label,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: presentation.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_waterQualityData!.lastUpdated}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(presentation.explanation, textAlign: TextAlign.center),
            if (_waterQualityData!.rawValue != null) ...[
              const SizedBox(height: 10),
              Text(
                '${_waterQualityData!.parameterName}: ${_waterQualityData!.rawValue} ${_waterQualityData!.unit}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DetailPage()),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View detailed indicators'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final presentation = _waterQualityData == null
                  ? QualityMapper.mapPh(null)
                  : QualityMapper.mapPh(_waterQualityData!.rawValue);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryPage(
                    stationName:
                        _waterQualityData?.stationName ?? 'Unknown station',
                    statusLabel: presentation.label,
                    parameterName:
                        _waterQualityData?.parameterName ?? 'Reading',
                    rawValue: _waterQualityData?.rawValue,
                    unit: _waterQualityData?.unit ?? '',
                    lastUpdated:
                        _waterQualityData?.lastUpdated ?? 'Unknown time',
                    trendSummary: _buildStoryTrendSummary(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Open Story Mode'),
          ),
        ),
      ],
    );
  }
}
