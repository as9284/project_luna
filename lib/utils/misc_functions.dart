import 'package:intl/intl.dart';

String formatDate(String rawDate) {
  try {
    final parsed = DateTime.parse(rawDate).toLocal();
    return DateFormat('MMM d, y – h:mm a').format(parsed);
  } catch (_) {
    return rawDate;
  }
}
