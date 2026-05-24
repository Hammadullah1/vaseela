class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final String status; // 'pending' or 'disbursed'

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    this.status = 'pending',
  });
}
