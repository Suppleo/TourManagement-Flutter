class Helpers {
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static bool isAdmin(String? role) {
    return role == 'admin';
  }

  static bool isCustomer(String? role) {
    return role == 'customer';
  }
}
