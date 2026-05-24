class DonationRequest {
  String title;
  double amount;
  double donated;

  DonationRequest({
    required this.title,
    required this.amount,
    this.donated = 0,
  });
}
