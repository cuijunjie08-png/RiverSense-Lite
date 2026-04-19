class StoryData {
  final String title;
  final String body;

  const StoryData({required this.title, required this.body});
}

class StoryGenerator {
  static StoryData generate({
    required String statusLabel,
    required String parameterName,
    required double? rawValue,
    required String unit,
    required String trendSummary,
  }) {
    final valueText = rawValue == null
        ? 'No valid reading is currently available'
        : '$rawValue $unit'.trim();

    switch (statusLabel) {
      case 'Good':
        return StoryData(
          title: 'Why is this river rated "Good" today?',
          body:
              'The latest $parameterName reading is $valueText, which falls within a generally acceptable range. '
              'This suggests that current conditions at the selected monitoring point appear relatively stable.\n\n'
              '$trendSummary\n\n'
              'This does not guarantee that every aspect of water quality is ideal, but it indicates that the latest available reading does not show an obvious warning sign.',
        );

      case 'Moderate':
        return StoryData(
          title: 'Why is this river rated "Moderate" today?',
          body:
              'The latest $parameterName reading is $valueText, which is slightly outside the preferred range. '
              'This suggests that conditions are not severely abnormal, but they may deserve closer attention.\n\n'
              '$trendSummary\n\n'
              'This does not necessarily indicate a major pollution event. However, it suggests that the river section may be experiencing some environmental pressure or short-term fluctuation.',
        );

      case 'Poor':
        return StoryData(
          title: 'Why is this river rated "Poor" today?',
          body:
              'The latest $parameterName reading is $valueText, which is notably outside the preferred range. '
              'This suggests that current water conditions may be less healthy than expected.\n\n'
              '$trendSummary\n\n'
              'This does not automatically confirm a severe pollution incident, but it does mean that this location is worth paying closer attention to and monitoring over time.',
        );

      default:
        return const StoryData(
          title: 'Why is this river status unknown today?',
          body:
              'No reliable reading is currently available for this site, so the app cannot generate a confident explanation. '
              'Try refreshing the page or checking again later when more monitoring data becomes available.',
        );
    }
  }
}
