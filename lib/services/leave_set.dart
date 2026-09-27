class LeaveType {
  final String code;
  final String name;
  final int totalDays;

  const LeaveType({
    required this.code,
    required this.name,
    required this.totalDays,
  });
}

class LeaveSet {
  static const List<LeaveType> leaves = [
    LeaveType(
      code: 'SL',
      name: 'Sick Leave',
      totalDays: 10,
    ),
    LeaveType(
      code: 'CL',
      name: 'Casual Leave',
      totalDays: 20,
    ),
    LeaveType(
      code: 'EL',
      name: 'Earned Leave',
      totalDays: 30,
    ),
    LeaveType(
      code: 'FL',
      name: 'Flexi Leave',
      totalDays: 10,
    ),
  ];

  static LeaveType getByCode(String code) {
    return leaves.firstWhere(
      (leave) => leave.code == code,
    );
  }
}