import '../app/profile.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Degrees inside a sign as 12°34'.
String fmtDeg(double deg) {
  var d = deg.floor();
  var m = ((deg - d) * 60).round();
  if (m == 60) {
    d += 1;
    m = 0;
  }
  return "$d°${two(m)}'";
}

String fmtTime(int h, int m) {
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${two(m)} ${h < 12 ? 'AM' : 'PM'}';
}

String fmtOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final a = minutes.abs();
  return 'UTC$sign${a ~/ 60}:${two(a % 60)}';
}

String fmtYears(double y) {
  final whole = y.floor();
  final months = ((y - whole) * 12).floor();
  return '${whole}y ${months}m';
}

String birthLine(Profile p) =>
    '${fmtDate(DateTime.utc(p.year, p.month, p.day))}, ${fmtTime(p.hour, p.minute)} - ${p.place.name}';
