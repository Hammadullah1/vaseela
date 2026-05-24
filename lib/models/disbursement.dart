class Disbursement {
  String title;
  double amount;
  bool verified;

  Disbursement({
    required this.title,
    required this.amount,
    this.verified = false,
  });
}
