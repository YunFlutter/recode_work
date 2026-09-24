import 'package:flutter/material.dart';

class WorkSession {
  const WorkSession({this.startTime, this.endTime});

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
}
