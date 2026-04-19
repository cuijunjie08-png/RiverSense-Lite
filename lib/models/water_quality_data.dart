class WaterQualityData {
  final String stationName;
  final String overallStatus;
  final String lastUpdated;
  final String summary;
  final double? rawValue;
  final String parameterName;
  final String unit;

  const WaterQualityData({
    required this.stationName,
    required this.overallStatus,
    required this.lastUpdated,
    required this.summary,
    required this.rawValue,
    required this.parameterName,
    required this.unit,
  });
}
