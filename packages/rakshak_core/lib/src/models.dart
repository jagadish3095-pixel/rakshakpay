// Plain data classes for the JSON the server sends. Money is always in paise.

class Branch {
  Branch.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        bankCode = j['bank_code'],
        name = j['name'],
        city = j['city'],
        state = j['state'],
        ifsc = j['ifsc'],
        lat = (j['lat'] as num).toDouble(),
        lng = (j['lng'] as num).toDouble();

  final int id;
  final String bankCode, name, city, state, ifsc;
  final double lat, lng;
}

class Atm {
  Atm.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        bankCode = j['bank_code'],
        name = j['name'],
        address = j['address'],
        city = j['city'],
        state = j['state'],
        lat = (j['lat'] as num).toDouble(),
        lng = (j['lng'] as num).toDouble();

  final String id, bankCode, name, address, city, state;
  final double lat, lng;
}

class City {
  City.fromJson(Map<String, dynamic> j)
      : name = j['name'],
        state = j['state'],
        lat = (j['lat'] as num).toDouble(),
        lng = (j['lng'] as num).toDouble();

  final String name, state;
  final double lat, lng;
}

class Account {
  Account.fromJson(Map<String, dynamic> j)
      : accountNo = j['account_no'],
        bankCode = j['bank_code'],
        accountType = j['account_type'],
        businessName = j['business_name'] ?? '',
        holderName = j['holder_name'],
        branch = Branch.fromJson(j['branch']),
        balance = j['balance'],
        lienAmount = j['lien_amount'],
        availableBalance = j['available_balance'],
        status = j['status'],
        cardNo = j['card_no'],
        cardExpiry = j['card_expiry'] ?? '',
        cardBlocked = j['card_blocked'],
        openedOn = j['opened_on'];

  final String accountNo, bankCode, accountType, businessName, holderName, status, cardNo, cardExpiry, openedOn;
  final Branch branch;
  final int balance, lienAmount, availableBalance;
  final bool cardBlocked;

  bool get isActive => status == 'ACTIVE';
  bool get isMerchant => accountType == 'CURRENT';
  String get typeLabel => isMerchant ? 'Current (Merchant)' : 'Savings';
}

class Customer {
  Customer.fromJson(Map<String, dynamic> j)
      : cif = j['cif'],
        bankCode = j['bank_code'],
        fullName = j['full_name'],
        dob = j['dob'],
        gender = j['gender'],
        mobile = j['mobile'],
        email = j['email'] ?? '',
        pan = j['pan'],
        aadhaarMasked = j['aadhaar_masked'],
        address = j['address'],
        city = j['city'],
        state = j['state'],
        pincode = j['pincode'],
        accounts = [for (final a in j['accounts']) Account.fromJson(a)];

  final String cif, bankCode, fullName, dob, gender, mobile, email, pan, aadhaarMasked;
  final String address, city, state, pincode;
  final List<Account> accounts;
}

class PassbookEntry {
  PassbookEntry.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        date = j['date'],
        type = j['type'],
        amount = j['amount'],
        balanceAfter = j['balance_after'],
        narration = j['narration'],
        utr = j['utr'],
        channel = j['channel'],
        remark = j['remark'] ?? '',
        locationLabel = j['location_label'] ?? '';

  final int id, amount, balanceAfter;
  final String date, type, narration, utr, channel, remark, locationLabel;

  bool get isCredit => type == 'CR';
}
