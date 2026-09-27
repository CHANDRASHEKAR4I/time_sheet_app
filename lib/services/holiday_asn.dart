class HolidayAsn {
  // Fixed national holidays in India.
  //
  // These holidays are independent of the user's location.
  static const Map<String, String> nationalHolidays = {
    '01-26': 'Republic Day',
    '08-15': 'Independence Day',
    '10-02': 'Gandhi Jayanti',
  };

  static bool isNationalHoliday(DateTime date) {
    final key =
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return nationalHolidays.containsKey(key);
  }

  static String? getHolidayName(DateTime date) {
    final key =
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return nationalHolidays[key];
  }
}