class BusinessCardDraft {
  const BusinessCardDraft({
    this.fullName = '',
    this.company = '',
    this.role = '',
    this.emails = const [],
    this.linkedinUrl = '',
    this.rawText = '',
    this.usedOfflineFallback = false,
  });

  final String fullName;
  final String company;
  final String role;
  final List<String> emails;
  final String linkedinUrl;
  final String rawText;
  final bool usedOfflineFallback;

  factory BusinessCardDraft.fromFunctionData(
    Map<String, Object?> data, {
    required String rawText,
  }) => BusinessCardDraft(
    fullName: _string(data['fullName']),
    company: _string(data['company']),
    role: _string(data['role']),
    emails: _strings(data['emails']),
    linkedinUrl: _string(data['linkedinUrl']),
    rawText: rawText,
  );

  factory BusinessCardDraft.offline(String rawText) {
    final emails = RegExp(
      r'[^\s<>()\[\],;:]+@[^\s<>()\[\],;:]+\.[A-Za-z]{2,}',
      caseSensitive: false,
    ).allMatches(rawText).map((match) => match.group(0)!.toLowerCase()).toSet();
    final linkedIn = RegExp(
      r'(?:https?://)?(?:www\.)?linkedin\.(?:com|fr)/[^\s<>()]+',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(0);
    return BusinessCardDraft(
      emails: emails.toList(),
      linkedinUrl: linkedIn == null
          ? ''
          : linkedIn.startsWith('http')
          ? linkedIn
          : 'https://$linkedIn',
      rawText: rawText,
      usedOfflineFallback: true,
    );
  }

  static String _string(Object? value) => value is String ? value.trim() : '';

  static List<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
      : const [];
}
