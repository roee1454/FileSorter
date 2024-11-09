// lib/utils.dart
import 'package:intl/intl.dart';

String processText(String text) {
  return Bidi.stripHtmlIfNeeded(text);
}
