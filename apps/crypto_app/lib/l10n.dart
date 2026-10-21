/// Hindi and Kannada text for this app, keyed by the English text passed to tr().
const appTranslations = <String, Map<String, String>>{
  'hi': {
    // models.dart (history titles)
    'Deposited rupees': 'रुपये जमा किए',
    'Bought {asset}': '{asset} खरीदा',
    'Sold {asset}': '{asset} बेचा',
    'Withdrew to bank': 'बैंक में निकाले',
    'Sent {asset} to outside wallet': '{asset} बाहरी वॉलेट में भेजा',
    // coin_screen.dart
    'Enter an amount': 'रकम डालें',
    'Enter a quantity': 'मात्रा डालें',
    'Buy {asset} for {amount}': '{amount} में {asset} खरीदें',
    'Sell {qty} {asset}': '{qty} {asset} बेचें',
    'Send {qty} {asset} to an outside wallet': '{qty} {asset} बाहरी वॉलेट में भेजें',
    'Enter CoinVault PIN': 'CoinVault PIN डालें',
    '{arrow} {pct}% (1 hour)': '{arrow} {pct}% (1 घंटा)',
    'You hold': 'आपके पास',
    'INR wallet': 'INR वॉलेट',
    'Buy': 'खरीदें',
    'Sell': 'बेचें',
    'Send': 'भेजें',
    'Please wait…': 'कृपया रुकें…',
    'MAX': 'पूरा',
    'Spend (min ₹100)': 'खर्च करें (कम से कम ₹100)',
    'You get ≈ {amount}': 'आपको मिलेगा ≈ {amount}',
    'Quantity ({asset})': 'मात्रा ({asset})',
    'Coins sent to an outside wallet leave CoinVault. They cannot be frozen, '
            'reversed or recovered by CoinVault, your bank or the police.':
        'बाहरी वॉलेट में भेजे गए कॉइन CoinVault से बाहर चले जाते हैं। CoinVault, आपका बैंक या पुलिस '
            'उन्हें न रोक सकते हैं, न वापस कर सकते हैं, न रिकवर कर सकते हैं।',
    'Outside wallet address': 'बाहरी वॉलेट एड्रेस',
    'e.g. {example}': 'जैसे {example}',
    // deposit_screen.dart
    'No UPI app found. Install RakshakPay.': 'कोई UPI ऐप नहीं मिला। RakshakPay इंस्टॉल करें।',
    'Deposit rupees': 'रुपये जमा करें',
    'Amount': 'रकम',
    'Pay only from your own bank account: {bank} {account}.\n'
            'Payments from anyone else\'s account are refunded automatically.':
        'सिर्फ़ अपने बैंक खाते से ही पेमेंट करें: {bank} {account}।\n'
            'किसी और के खाते से आया पेमेंट अपने-आप वापस कर दिया जाता है।',
    'Pay with RakshakPay': 'RakshakPay से पेमेंट करें',
    'or scan with any UPI app': 'या किसी भी UPI ऐप से स्कैन करें',
    'UPI ID copied': 'UPI ID कॉपी हो गई',
    'After paying, come back here. Your INR wallet updates automatically.':
        'पेमेंट के बाद यहाँ वापस आएँ। आपका INR वॉलेट अपने-आप अपडेट हो जाएगा।',
    // history_screen.dart
    'History': 'हिस्ट्री',
    'Nothing yet': 'अभी कुछ नहीं',
    'to {address}': '{address} को',
    'UTR {utr}': 'UTR {utr}',
    // home_screen.dart
    'Change CoinVault PIN': 'CoinVault PIN बदलें',
    'Change PIN': 'PIN बदलें',
    'Settings': 'सेटिंग्स',
    'Log out': 'लॉग आउट',
    'Hi, {name}': 'नमस्ते, {name}',
    'Portfolio value': 'पोर्टफोलियो वैल्यू',
    'Linked bank: {bank} {account}': 'जुड़ा बैंक: {bank} {account}',
    'Deposit': 'जमा करें',
    'Withdraw': 'निकालें',
    'Markets': 'मार्केट',
    // lock_screen.dart
    'Enter your 4-digit CoinVault PIN': 'अपना 4 अंकों का CoinVault PIN डालें',
    // withdraw_screen.dart
    'Withdraw {amount} to your bank': '{amount} अपने बैंक में निकालें',
    'Withdraw to bank': 'बैंक में निकालें',
    'Available: {amount}': 'उपलब्ध: {amount}',
    'To {bank}': '{bank} में',
    'A/c {account} (your KYC account) • IMPS': 'खाता {account} (आपका KYC खाता) • IMPS',
    'Sending…': 'भेजा जा रहा है…',
    // register_screen.dart
    'Enter a valid mobile number': 'सही मोबाइल नंबर डालें',
    'SMS (demo)': 'SMS (डेमो)',
    'Your CoinVault code is {code}': 'आपका CoinVault कोड {code} है',
    'OK': 'ठीक है',
    'Verify your mobile number first': 'पहले अपना मोबाइल नंबर वेरिफ़ाई करें',
    'KYC verified. Welcome, {name}!': 'KYC वेरिफ़ाई हो गया। स्वागत है, {name}!',
    'Create CoinVault account': 'CoinVault खाता बनाएँ',
    'Mobile number': 'मोबाइल नंबर',
    'Send OTP': 'OTP भेजें',
    'Resend': 'फिर से भेजें',
    'Enter OTP': 'OTP डालें',
    'Verify': 'वेरिफ़ाई करें',
    'Wrong OTP': 'गलत OTP',
    'Indian law requires PAN for crypto exchanges. Your bank account must be in the same PAN; '
            'your name is taken from it. Deposits are accepted only from this account.':
        'भारतीय कानून के अनुसार क्रिप्टो एक्सचेंज के लिए PAN ज़रूरी है। आपका बैंक खाता इसी PAN पर होना चाहिए; '
            'आपका नाम उसी से लिया जाता है। जमा सिर्फ़ इसी खाते से स्वीकार होगा।',
    'Format: {example}': 'फ़ॉर्मेट: {example}',
    'Bank account number': 'बैंक खाता नंबर',
    'Enter your account number': 'अपना खाता नंबर डालें',
    '11 characters': '11 अक्षर',
    'Set 4-digit PIN (login & every trade)': '4 अंकों का PIN सेट करें (लॉगिन और हर ट्रेड के लिए)',
    '4 digits': '4 अंक',
    'Confirm PIN': 'PIN दोबारा डालें',
    'PINs do not match': 'दोनों PIN मेल नहीं खाते',
    'Verifying KYC…': 'KYC वेरिफ़ाई हो रहा है…',
    'Verify KYC & create account': 'KYC वेरिफ़ाई करें और खाता बनाएँ',
    // welcome_screen.dart
    'Buy, sell and store crypto in India': 'भारत में क्रिप्टो खरीदें, बेचें और रखें',
    'Demo exchange • Fake coins and fake money': 'डेमो एक्सचेंज • नकली कॉइन और नकली पैसे',
    'Not connected to the server': 'सर्वर से कनेक्ट नहीं है',
    'Check internet, or the address in Settings (top right).':
        'इंटरनेट जाँचें, या सेटिंग्स (ऊपर दाईं ओर) में एड्रेस देखें।',
    '4-digit PIN': '4 अंकों का PIN',
    'Logging in…': 'लॉगिन हो रहा है…',
    'Log in': 'लॉगिन करें',
    'Create account (KYC)': 'खाता बनाएँ (KYC)',
  },
  'kn': {
    // models.dart (history titles)
    'Deposited rupees': 'ರೂಪಾಯಿ ಜಮಾ ಮಾಡಲಾಗಿದೆ',
    'Bought {asset}': '{asset} ಖರೀದಿಸಲಾಗಿದೆ',
    'Sold {asset}': '{asset} ಮಾರಾಟ ಮಾಡಲಾಗಿದೆ',
    'Withdrew to bank': 'ಬ್ಯಾಂಕ್‌ಗೆ ಹಿಂಪಡೆಯಲಾಗಿದೆ',
    'Sent {asset} to outside wallet': '{asset} ಹೊರಗಿನ ವಾಲೆಟ್‌ಗೆ ಕಳುಹಿಸಲಾಗಿದೆ',
    // coin_screen.dart
    'Enter an amount': 'ಮೊತ್ತ ನಮೂದಿಸಿ',
    'Enter a quantity': 'ಪ್ರಮಾಣ ನಮೂದಿಸಿ',
    'Buy {asset} for {amount}': '{amount}ಗೆ {asset} ಖರೀದಿಸಿ',
    'Sell {qty} {asset}': '{qty} {asset} ಮಾರಾಟ ಮಾಡಿ',
    'Send {qty} {asset} to an outside wallet': '{qty} {asset} ಹೊರಗಿನ ವಾಲೆಟ್‌ಗೆ ಕಳುಹಿಸಿ',
    'Enter CoinVault PIN': 'CoinVault PIN ನಮೂದಿಸಿ',
    '{arrow} {pct}% (1 hour)': '{arrow} {pct}% (1 ಗಂಟೆ)',
    'You hold': 'ನಿಮ್ಮ ಬಳಿ ಇರುವುದು',
    'INR wallet': 'INR ವಾಲೆಟ್',
    'Buy': 'ಖರೀದಿಸಿ',
    'Sell': 'ಮಾರಾಟ ಮಾಡಿ',
    'Send': 'ಕಳುಹಿಸಿ',
    'Please wait…': 'ದಯವಿಟ್ಟು ಕಾಯಿರಿ…',
    'MAX': 'ಪೂರ್ತಿ',
    'Spend (min ₹100)': 'ಖರ್ಚು ಮಾಡಿ (ಕನಿಷ್ಠ ₹100)',
    'You get ≈ {amount}': 'ನಿಮಗೆ ಸಿಗುವುದು ≈ {amount}',
    'Quantity ({asset})': 'ಪ್ರಮಾಣ ({asset})',
    'Coins sent to an outside wallet leave CoinVault. They cannot be frozen, '
            'reversed or recovered by CoinVault, your bank or the police.':
        'ಹೊರಗಿನ ವಾಲೆಟ್‌ಗೆ ಕಳುಹಿಸಿದ ಕಾಯಿನ್‌ಗಳು CoinVault ನಿಂದ ಹೊರಹೋಗುತ್ತವೆ. CoinVault, ನಿಮ್ಮ ಬ್ಯಾಂಕ್ ಅಥವಾ ಪೊಲೀಸ್ '
            'ಅವುಗಳನ್ನು ತಡೆಹಿಡಿಯಲು, ಹಿಂತಿರುಗಿಸಲು ಅಥವಾ ಮರುಪಡೆಯಲು ಸಾಧ್ಯವಿಲ್ಲ.',
    'Outside wallet address': 'ಹೊರಗಿನ ವಾಲೆಟ್ ವಿಳಾಸ',
    'e.g. {example}': 'ಉದಾ. {example}',
    // deposit_screen.dart
    'No UPI app found. Install RakshakPay.': 'ಯಾವುದೇ UPI ಆ್ಯಪ್ ಸಿಗಲಿಲ್ಲ. RakshakPay ಇನ್‌ಸ್ಟಾಲ್ ಮಾಡಿ.',
    'Deposit rupees': 'ರೂಪಾಯಿ ಜಮಾ ಮಾಡಿ',
    'Amount': 'ಮೊತ್ತ',
    'Pay only from your own bank account: {bank} {account}.\n'
            'Payments from anyone else\'s account are refunded automatically.':
        'ನಿಮ್ಮ ಸ್ವಂತ ಬ್ಯಾಂಕ್ ಖಾತೆಯಿಂದ ಮಾತ್ರ ಪಾವತಿಸಿ: {bank} {account}.\n'
            'ಬೇರೆಯವರ ಖಾತೆಯಿಂದ ಬಂದ ಪಾವತಿಯನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಹಿಂತಿರುಗಿಸಲಾಗುತ್ತದೆ.',
    'Pay with RakshakPay': 'RakshakPay ಮೂಲಕ ಪಾವತಿಸಿ',
    'or scan with any UPI app': 'ಅಥವಾ ಯಾವುದೇ UPI ಆ್ಯಪ್‌ನಿಂದ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'UPI ID copied': 'UPI ID ಕಾಪಿ ಆಯಿತು',
    'After paying, come back here. Your INR wallet updates automatically.':
        'ಪಾವತಿಸಿದ ನಂತರ ಇಲ್ಲಿಗೆ ಹಿಂತಿರುಗಿ. ನಿಮ್ಮ INR ವಾಲೆಟ್ ತಾನಾಗಿಯೇ ಅಪ್‌ಡೇಟ್ ಆಗುತ್ತದೆ.',
    // history_screen.dart
    'History': 'ಇತಿಹಾಸ',
    'Nothing yet': 'ಇನ್ನೂ ಏನೂ ಇಲ್ಲ',
    'to {address}': '{address} ಗೆ',
    'UTR {utr}': 'UTR {utr}',
    // home_screen.dart
    'Change CoinVault PIN': 'CoinVault PIN ಬದಲಿಸಿ',
    'Change PIN': 'PIN ಬದಲಿಸಿ',
    'Settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'Log out': 'ಲಾಗ್ ಔಟ್',
    'Hi, {name}': 'ನಮಸ್ಕಾರ, {name}',
    'Portfolio value': 'ಪೋರ್ಟ್‌ಫೋಲಿಯೊ ಮೌಲ್ಯ',
    'Linked bank: {bank} {account}': 'ಲಿಂಕ್ ಮಾಡಿದ ಬ್ಯಾಂಕ್: {bank} {account}',
    'Deposit': 'ಜಮಾ ಮಾಡಿ',
    'Withdraw': 'ಹಿಂಪಡೆಯಿರಿ',
    'Markets': 'ಮಾರುಕಟ್ಟೆಗಳು',
    // lock_screen.dart
    'Enter your 4-digit CoinVault PIN': 'ನಿಮ್ಮ 4 ಅಂಕಿಯ CoinVault PIN ನಮೂದಿಸಿ',
    // withdraw_screen.dart
    'Withdraw {amount} to your bank': '{amount} ನಿಮ್ಮ ಬ್ಯಾಂಕ್‌ಗೆ ಹಿಂಪಡೆಯಿರಿ',
    'Withdraw to bank': 'ಬ್ಯಾಂಕ್‌ಗೆ ಹಿಂಪಡೆಯಿರಿ',
    'Available: {amount}': 'ಲಭ್ಯವಿರುವುದು: {amount}',
    'To {bank}': '{bank} ಗೆ',
    'A/c {account} (your KYC account) • IMPS': 'ಖಾತೆ {account} (ನಿಮ್ಮ KYC ಖಾತೆ) • IMPS',
    'Sending…': 'ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ…',
    // register_screen.dart
    'Enter a valid mobile number': 'ಸರಿಯಾದ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ',
    'SMS (demo)': 'SMS (ಡೆಮೊ)',
    'Your CoinVault code is {code}': 'ನಿಮ್ಮ CoinVault ಕೋಡ್ {code}',
    'OK': 'ಸರಿ',
    'Verify your mobile number first': 'ಮೊದಲು ನಿಮ್ಮ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಪರಿಶೀಲಿಸಿ',
    'KYC verified. Welcome, {name}!': 'KYC ಪರಿಶೀಲನೆ ಆಯಿತು. ಸ್ವಾಗತ, {name}!',
    'Create CoinVault account': 'CoinVault ಖಾತೆ ತೆರೆಯಿರಿ',
    'Mobile number': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ',
    'Send OTP': 'OTP ಕಳುಹಿಸಿ',
    'Resend': 'ಮತ್ತೆ ಕಳುಹಿಸಿ',
    'Enter OTP': 'OTP ನಮೂದಿಸಿ',
    'Verify': 'ಪರಿಶೀಲಿಸಿ',
    'Wrong OTP': 'ತಪ್ಪು OTP',
    'Indian law requires PAN for crypto exchanges. Your bank account must be in the same PAN; '
            'your name is taken from it. Deposits are accepted only from this account.':
        'ಭಾರತೀಯ ಕಾನೂನಿನ ಪ್ರಕಾರ ಕ್ರಿಪ್ಟೋ ಎಕ್ಸ್‌ಚೇಂಜ್‌ಗಳಿಗೆ PAN ಕಡ್ಡಾಯ. ನಿಮ್ಮ ಬ್ಯಾಂಕ್ ಖಾತೆ ಇದೇ PAN ನಲ್ಲಿರಬೇಕು; '
            'ನಿಮ್ಮ ಹೆಸರನ್ನು ಅದರಿಂದಲೇ ತೆಗೆದುಕೊಳ್ಳಲಾಗುತ್ತದೆ. ಈ ಖಾತೆಯಿಂದ ಮಾತ್ರ ಜಮಾ ಸ್ವೀಕರಿಸಲಾಗುತ್ತದೆ.',
    'Format: {example}': 'ಫಾರ್ಮ್ಯಾಟ್: {example}',
    'Bank account number': 'ಬ್ಯಾಂಕ್ ಖಾತೆ ಸಂಖ್ಯೆ',
    'Enter your account number': 'ನಿಮ್ಮ ಖಾತೆ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ',
    '11 characters': '11 ಅಕ್ಷರಗಳು',
    'Set 4-digit PIN (login & every trade)': '4 ಅಂಕಿಯ PIN ಹೊಂದಿಸಿ (ಲಾಗಿನ್ ಮತ್ತು ಪ್ರತಿ ಟ್ರೇಡ್‌ಗೆ)',
    '4 digits': '4 ಅಂಕಿಗಳು',
    'Confirm PIN': 'PIN ದೃಢೀಕರಿಸಿ',
    'PINs do not match': 'PIN ಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
    'Verifying KYC…': 'KYC ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ…',
    'Verify KYC & create account': 'KYC ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಖಾತೆ ತೆರೆಯಿರಿ',
    // welcome_screen.dart
    'Buy, sell and store crypto in India': 'ಭಾರತದಲ್ಲಿ ಕ್ರಿಪ್ಟೋ ಖರೀದಿಸಿ, ಮಾರಾಟ ಮಾಡಿ ಮತ್ತು ಸಂಗ್ರಹಿಸಿ',
    'Demo exchange • Fake coins and fake money': 'ಡೆಮೊ ಎಕ್ಸ್‌ಚೇಂಜ್ • ನಕಲಿ ಕಾಯಿನ್ ಮತ್ತು ನಕಲಿ ಹಣ',
    'Not connected to the server': 'ಸರ್ವರ್‌ಗೆ ಸಂಪರ್ಕವಿಲ್ಲ',
    'Check internet, or the address in Settings (top right).':
        'ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ, ಅಥವಾ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ (ಮೇಲೆ ಬಲಕ್ಕೆ) ವಿಳಾಸ ನೋಡಿ.',
    '4-digit PIN': '4 ಅಂಕಿಯ PIN',
    'Logging in…': 'ಲಾಗಿನ್ ಆಗುತ್ತಿದೆ…',
    'Log in': 'ಲಾಗಿನ್',
    'Create account (KYC)': 'ಖಾತೆ ತೆರೆಯಿರಿ (KYC)',
  },
};
