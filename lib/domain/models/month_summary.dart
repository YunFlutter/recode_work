class MonthSummary {
  const MonthSummary({
    required this.present,
    required this.overtime,
    required this.rest,
    required this.halfDay,
    required this.absent,
    required this.unrecorded,
  });

  final int present;
  final int overtime;
  final int rest;
  final int halfDay;
  final int absent;
  final int unrecorded;
}
