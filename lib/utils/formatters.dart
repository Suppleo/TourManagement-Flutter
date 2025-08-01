import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(num amount, {String locale = 'vi_VN'}) {
    final formatter = NumberFormat.currency(locale: locale, symbol: '₫');
    return formatter.format(amount);
  }

  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    final formatter = DateFormat(pattern);
    return formatter.format(date);
  }

  static String formatDateTime(DateTime date, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    final formatter = DateFormat(pattern);
    return formatter.format(date);
  }
}
