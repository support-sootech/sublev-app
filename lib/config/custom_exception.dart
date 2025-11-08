class CustomException implements Exception {
  int? codeNumber;
  String? codeString;
  String message;
  String? subMessage;
  CustomException({
    this.codeNumber,
    this.codeString,
    required this.message,
    this.subMessage,
  });

  @override
  String toString() {
    return message.toString();
  }
}
