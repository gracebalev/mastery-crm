class SimpleCsvCodec {
  const SimpleCsvCodec();

  List<List<String>> decode(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    void finishField() {
      row.add(field.toString());
      field.clear();
    }

    void finishRow() {
      finishField();
      if (row.any((cell) => cell.isNotEmpty)) rows.add(row);
      row = <String>[];
    }

    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      if (char == '"') {
        if (quoted && index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        finishField();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index++;
        }
        finishRow();
      } else {
        field.write(char);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) finishRow();
    return rows;
  }

  String encode(List<List<String>> rows) =>
      rows.map((row) => row.map(_escape).join(',')).join('\r\n');
  String _escape(String value) {
    if (!value.contains(RegExp('[",\\r\\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
