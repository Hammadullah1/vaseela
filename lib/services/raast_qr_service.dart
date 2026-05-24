class RaastQRService {
  static String generatePayload({
    required String iban,
    required String recipientName,
    required double amount,
    required String description,
  }) {
    final cleanIban = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final cleanName = _cap(recipientName.trim(), 25);
    final cleanDesc = _cap(description.trim(), 25);

    final amtStr = (amount % 1 == 0)
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);

    final f00 = _tlv('00', '01');
    final f01 = _tlv('01', '12');

    final sub27 =
        _tlv('00', 'PK.GOV.SBP.RAAST') +
        _tlv('01', cleanIban);
    final f27 = _tlv('27', sub27);

    final f52 = _tlv('52', '6012');
    final f53 = _tlv('53', '586');
    final f54 = _tlv('54', amtStr);
    final f58 = _tlv('58', 'PK');
    final f59 = _tlv('59', cleanName);
    final f60 = _tlv('60', 'Karachi');

    final sub62 = _tlv('08', cleanDesc);
    final f62   = _tlv('62', sub62);

    final body = f00 + f01 + f27 + f52 + f53 + f54 + f58 + f59 + f60 + f62;

    final crcInput = '${body}6304';
    final crcValue = _crc16ccitt(crcInput)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(4, '0');
    final f63 = _tlv('63', crcValue);

    return body + f63;
  }

  static String _tlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  static String _cap(String s, int max) =>
      s.length > max ? s.substring(0, max) : s;

  static int _crc16ccitt(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) & 0xFF) << 8;
      for (int bit = 0; bit < 8; bit++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}
