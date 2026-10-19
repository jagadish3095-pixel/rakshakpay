// UPI-specific data from the server. Money is always in paise.

class UpiVpa {
  UpiVpa.fromJson(Map<String, dynamic> j)
      : address = j['address'],
        bankCode = j['bank_code'],
        accountNoMasked = j['account_no_masked'],
        isMerchant = j['is_merchant'],
        displayName = j['display_name'],
        holderName = j['holder_name'],
        status = j['status'];

  final String address, bankCode, accountNoMasked, displayName, holderName, status;
  final bool isMerchant;
}

class UpiProfile {
  UpiProfile.fromJson(Map<String, dynamic> j)
      : mobile = j['mobile'],
        name = j['name'],
        vpas = [for (final v in j['vpas']) UpiVpa.fromJson(v)];

  final String mobile, name;
  final List<UpiVpa> vpas;

  UpiVpa? get primary => vpas.firstOrNull;
}

class UpiPayment {
  UpiPayment.fromJson(Map<String, dynamic> j)
      : utr = j['utr'],
        date = j['date'],
        sent = j['direction'] == 'SENT',
        amount = j['amount'],
        myVpa = j['my_vpa'],
        otherVpa = j['other_vpa'],
        otherName = j['other_name'],
        remark = j['remark'] ?? '',
        status = j['status'],
        locationLabel = j['location_label'] ?? '';

  final String utr, date, myVpa, otherVpa, otherName, remark, status, locationLabel;
  final bool sent;
  final int amount;
}
