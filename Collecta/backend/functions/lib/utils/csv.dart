import 'errors.dart';

class ParsedMemberRow {
  ParsedMemberRow({
    required this.fullName,
    required this.phone,
    this.email,
    this.gender,
  });
  final String fullName;
  final String phone;
  final String? email;
  final String? gender;
}

/// Minimal RFC-4180-ish CSV parser (handles quoted fields, embedded commas,
/// escaped quotes and CRLF). Sufficient for member-import spreadsheets
/// exported from Excel / Google Sheets.
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var inQuotes = false;
  final s = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else {
      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (c == '\n') {
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(c);
      }
    }
  }
  // Trailing field / row.
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// Parse a members CSV string into rows. Header row required; columns are
/// matched case-insensitively (name/fullName, phone/phoneNumber/msisdn,
/// email, gender).
List<ParsedMemberRow> parseMembersCsv(String content) {
  final rows = parseCsv(content).where((r) => r.any((c) => c.trim().isNotEmpty));
  if (rows.isEmpty) badRequest('CSV is empty');

  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  int idx(List<String> names) =>
      header.indexWhere((h) => names.contains(h));

  final nameIdx = idx(['fullname', 'full name', 'name']);
  final phoneIdx = idx(['phone', 'phonenumber', 'phone number', 'msisdn']);
  final emailIdx = idx(['email']);
  final genderIdx = idx(['gender']);
  if (nameIdx < 0 || phoneIdx < 0) {
    badRequest("CSV must contain 'name' and 'phone' columns");
  }

  final result = <ParsedMemberRow>[];
  final dataRows = rows.skip(1).toList();
  for (var i = 0; i < dataRows.length; i++) {
    final r = dataRows[i];
    String cell(int j) => (j >= 0 && j < r.length) ? r[j].trim() : '';
    final name = cell(nameIdx);
    final phone = cell(phoneIdx);
    if (name.isEmpty || phone.isEmpty) {
      badRequest("Row ${i + 2}: 'name' and 'phone' are required");
    }
    result.add(ParsedMemberRow(
      fullName: name,
      phone: phone,
      email: emailIdx >= 0 && cell(emailIdx).isNotEmpty ? cell(emailIdx) : null,
      gender:
          genderIdx >= 0 && cell(genderIdx).isNotEmpty ? cell(genderIdx) : null,
    ));
  }
  return result;
}

/// Serialise rows into a CSV string with a header row.
String toCsv(List<Map<String, dynamic>> rows, List<String> columns) {
  String esc(dynamic v) {
    final str = v?.toString() ?? '';
    return RegExp(r'[",\n]').hasMatch(str)
        ? '"${str.replaceAll('"', '""')}"'
        : str;
  }

  final buf = StringBuffer(columns.join(','))..write('\n');
  for (final r in rows) {
    buf.write(columns.map((c) => esc(r[c])).join(','));
    buf.write('\n');
  }
  return buf.toString();
}
