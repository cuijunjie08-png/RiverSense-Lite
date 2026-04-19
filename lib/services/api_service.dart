import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trend_point.dart';

import '../models/water_quality_data.dart';

class ApiService {
  static const String _base = 'https://environment.data.gov.uk/hydrology';

  static Future<WaterQualityData> fetchWaterQuality({
    required double latitude,
    required double longitude,
  }) async {
    final stationsUri = Uri.parse(
      '$_base/id/stations.json'
      '?lat=$latitude'
      '&long=$longitude'
      '&dist=5'
      '&observedProperty=ph'
      '&_limit=1',
    );

    final stationsResp = await http.get(stationsUri);
    if (stationsResp.statusCode != 200) {
      throw Exception('Failed to load nearby monitoring stations.');
    }

    final stationsJson = jsonDecode(stationsResp.body) as Map<String, dynamic>;
    final stationItems = (stationsJson['items'] as List?) ?? [];

    if (stationItems.isEmpty) {
      throw Exception('No nearby water-quality station found.');
    }

    final station = stationItems.first as Map<String, dynamic>;
    final stationName = (station['label'] ?? 'Unknown station').toString();

    String stationId = '';
    if (station['stationGuid'] != null) {
      stationId = station['stationGuid'].toString();
    } else if (station['notation'] != null) {
      stationId = station['notation'].toString();
    } else if (station['@id'] != null) {
      final idUrl = station['@id'].toString();
      stationId = idUrl.split('/').last;
    }

    if (stationId.isEmpty) {
      throw Exception('Could not determine station id.');
    }

    final measuresUri = Uri.parse(
      '$_base/id/measures.json'
      '?station=$stationId'
      '&observedProperty=ph',
    );

    final measuresResp = await http.get(measuresUri);
    if (measuresResp.statusCode != 200) {
      throw Exception('Failed to load station measures.');
    }

    final measuresJson = jsonDecode(measuresResp.body) as Map<String, dynamic>;
    final measureItems = (measuresJson['items'] as List?) ?? [];

    if (measureItems.isEmpty) {
      throw Exception('No pH measure found for this station.');
    }

    final measure = measureItems.first as Map<String, dynamic>;
    String measureId = '';

    if (measure['notation'] != null) {
      measureId = measure['notation'].toString();
    } else if (measure['@id'] != null) {
      final idUrl = measure['@id'].toString();
      measureId = idUrl.split('/').last;
    }

    if (measureId.isEmpty) {
      throw Exception('Could not determine measure id.');
    }

    final parameterName = (measure['parameterName'] ?? measure['label'] ?? 'PH')
        .toString();

    String unit = '';
    if (measure['unitName'] != null) {
      unit = measure['unitName'].toString();
    } else if (measure['unit'] is Map<String, dynamic>) {
      final unitMap = measure['unit'] as Map<String, dynamic>;
      unit = (unitMap['label'] ?? '').toString();
    }

    final readingsUri = Uri.parse(
      '$_base/id/measures/$measureId/readings.json?latest',
    );

    final readingsResp = await http.get(readingsUri);
    if (readingsResp.statusCode != 200) {
      throw Exception('Failed to load latest reading.');
    }

    final readingsJson = jsonDecode(readingsResp.body) as Map<String, dynamic>;
    final readingItems = (readingsJson['items'] as List?) ?? [];

    if (readingItems.isEmpty) {
      throw Exception('No latest reading available.');
    }

    final latest = readingItems.first as Map<String, dynamic>;
    final value = (latest['value'] as num?)?.toDouble();
    final dateTime = (latest['dateTime'] ?? latest['date'] ?? 'Unknown time')
        .toString();

    return WaterQualityData(
      stationName: stationName,
      overallStatus: '',
      lastUpdated: dateTime,
      summary: '',
      rawValue: value,
      parameterName: parameterName,
      unit: unit,
    );
  }

  static Future<List<TrendPoint>> fetchWaterQualityTrend({
    required double latitude,
    required double longitude,
    required int days,
  }) async {
    final stationAndMeasure = await _findNearestPhMeasure(
      latitude: latitude,
      longitude: longitude,
    );

    final measureId = stationAndMeasure['measureId']!;
    final end = DateTime.now().toUtc();
    final start = end.subtract(Duration(days: days));

    final readingsUri = Uri.parse(
      '$_base/id/measures/$measureId/readings.json'
      '?min-date=${_formatDate(start)}'
      '&max-date=${_formatDate(end)}'
      '&_limit=500',
    );

    final readingsResp = await http.get(readingsUri);
    if (readingsResp.statusCode != 200) {
      throw Exception('Failed to load historical readings.');
    }

    final readingsJson = jsonDecode(readingsResp.body) as Map<String, dynamic>;
    final items = (readingsJson['items'] as List?) ?? [];

    if (items.isEmpty) {
      throw Exception('No historical readings available.');
    }

    final points = <TrendPoint>[];

    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final value = (map['value'] as num?)?.toDouble();
      final dateTimeStr = (map['dateTime'] ?? map['date'] ?? '')
          .toString()
          .trim();

      if (value == null || dateTimeStr.isEmpty) continue;

      final parsedTime = DateTime.tryParse(dateTimeStr);
      if (parsedTime == null) continue;

      points.add(TrendPoint(time: parsedTime.toLocal(), value: value));
    }

    points.sort((a, b) => a.time.compareTo(b.time));

    if (points.isEmpty) {
      throw Exception('No valid historical readings available.');
    }

    return points;
  }

  static Future<Map<String, String>> _findNearestPhMeasure({
    required double latitude,
    required double longitude,
  }) async {
    final stationsUri = Uri.parse(
      '$_base/id/stations.json'
      '?lat=$latitude'
      '&long=$longitude'
      '&dist=5'
      '&observedProperty=ph'
      '&_limit=1',
    );

    final stationsResp = await http.get(stationsUri);
    if (stationsResp.statusCode != 200) {
      throw Exception('Failed to load nearby monitoring stations.');
    }

    final stationsJson = jsonDecode(stationsResp.body) as Map<String, dynamic>;
    final stationItems = (stationsJson['items'] as List?) ?? [];

    if (stationItems.isEmpty) {
      throw Exception('No nearby water-quality station found.');
    }

    final station = stationItems.first as Map<String, dynamic>;
    final stationName = (station['label'] ?? 'Unknown station').toString();

    String stationId = '';
    if (station['stationGuid'] != null) {
      stationId = station['stationGuid'].toString();
    } else if (station['notation'] != null) {
      stationId = station['notation'].toString();
    } else if (station['@id'] != null) {
      final idUrl = station['@id'].toString();
      stationId = idUrl.split('/').last;
    }

    if (stationId.isEmpty) {
      throw Exception('Could not determine station id.');
    }

    final measuresUri = Uri.parse(
      '$_base/id/measures.json'
      '?station=$stationId'
      '&observedProperty=ph',
    );

    final measuresResp = await http.get(measuresUri);
    if (measuresResp.statusCode != 200) {
      throw Exception('Failed to load station measures.');
    }

    final measuresJson = jsonDecode(measuresResp.body) as Map<String, dynamic>;
    final measureItems = (measuresJson['items'] as List?) ?? [];

    if (measureItems.isEmpty) {
      throw Exception('No pH measure found for this station.');
    }

    final measure = measureItems.first as Map<String, dynamic>;

    String measureId = '';
    if (measure['notation'] != null) {
      measureId = measure['notation'].toString();
    } else if (measure['@id'] != null) {
      final idUrl = measure['@id'].toString();
      measureId = idUrl.split('/').last;
    }

    if (measureId.isEmpty) {
      throw Exception('Could not determine measure id.');
    }

    return {'stationName': stationName, 'measureId': measureId};
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
