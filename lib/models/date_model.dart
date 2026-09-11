class DateModel {
  int day;
  String date;
  String month;
  String year;
  String status; // "Present", "Absent", "Holiday", "None"

  DateModel({
    required this.day,
    required this.date,
    required this.month,
    required this.year,
    this.status = 'None',
  });
}
