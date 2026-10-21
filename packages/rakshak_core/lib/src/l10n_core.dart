// Hindi and Kannada for the shared screens in rakshak_core, the most common server error
// messages, complaint categories and notice titles. Keys are the exact English text.
// Check with: python tools/check_translations.py core

const coreTranslations = <String, Map<String, String>>{
  'hi': {
    // ---------------------------------------------------------------- app lock
    'Welcome back': 'फिर से स्वागत है',
    'Welcome back, {name}': 'फिर से स्वागत है, {name}',
    'Log out / switch user': 'लॉग आउट / यूज़र बदलें',
    'Too many wrong attempts. Please log in again.': 'बहुत बार गलत कोशिश हुई। कृपया फिर से लॉग इन करें।',
    '{message}. {count} tries left.': '{message}। {count} कोशिशें बाकी हैं।',
    'Enter your 4-digit MPIN': 'अपना 4 अंकों का MPIN डालें',
    'Enter your 4-digit passcode': 'अपना 4 अंकों का पासकोड डालें',
    'Enter your RakshakPay passcode': 'अपना RakshakPay पासकोड डालें',
    'Enter your 4-digit CoinVault PIN': 'अपना 4 अंकों का CoinVault PIN डालें',

    // ---------------------------------------------------------------- PIN dialog, common buttons
    'Enter 4-digit PIN': '4 अंकों का PIN डालें',
    'Enter UPI PIN': 'UPI PIN डालें',
    'Enter CoinVault PIN': 'CoinVault PIN डालें',
    'Pay {amount}': '{amount} भुगतान करें',
    'Cancel': 'रद्द करें',
    'Confirm': 'पुष्टि करें',
    'Done': 'हो गया',
    'Try again': 'फिर से कोशिश करें',

    // ---------------------------------------------------------------- account status
    'Active': 'सक्रिय',
    'Under verification': 'सत्यापन जारी है',
    'Blocked – fraud': 'ब्लॉक – धोखाधड़ी',
    'Current (Merchant)': 'चालू (व्यापारी)',
    'Savings': 'बचत',

    // ---------------------------------------------------------------- change password / PIN
    'password': 'पासवर्ड',
    'passcode': 'पासकोड',
    'Enter {count} digits': '{count} अंक डालें',
    'At least 6 characters': 'कम से कम 6 अक्षर',
    'Must be different from the current {what}': 'मौजूदा {what} से अलग होना चाहिए',
    'Too easy to guess (all the same digit)': 'अनुमान लगाना बहुत आसान है (सभी अंक एक जैसे)',
    'Too easy to guess (a sequence)': 'अनुमान लगाना बहुत आसान है (क्रम में अंक)',
    '{what} changed': '{what} बदल दिया गया',
    'Current {what}': 'मौजूदा {what}',
    'Required': 'ज़रूरी है',
    'New {what}': 'नया {what}',
    'Confirm new {what}': 'नया {what} दोबारा डालें',
    'Does not match': 'मेल नहीं खाता',
    'Saving…': 'सेव हो रहा है…',
    'Change {what}': '{what} बदलें',
    'Never share your {what} with anyone, including callers who say they are from the bank, police or RBI.':
        'अपना {what} किसी के साथ साझा न करें, उन कॉल करने वालों के साथ भी नहीं जो खुद को बैंक, पुलिस या RBI से बताते हैं।',

    // ---------------------------------------------------------------- fraud complaints
    'Report fraud (1930)': 'धोखाधड़ी की शिकायत (1930)',
    '{amount} paid to {name}': '{name} को {amount} का भुगतान',
    'UTR': 'UTR',
    "Report as soon as possible: money that is still in the fraudster's accounts can be held only before it is withdrawn.":
        'जितनी जल्दी हो सके शिकायत करें: धोखेबाज़ के खातों में जो पैसा अभी बचा है, उसे निकाले जाने से पहले ही रोका जा सकता है।',
    'What happened?': 'क्या हुआ?',
    'Choose what happened': 'चुनें कि क्या हुआ',
    'Please confirm the declaration': 'कृपया घोषणा की पुष्टि करें',
    'Describe what happened (optional)': 'क्या हुआ, बताएं (वैकल्पिक)',
    'e.g. A caller said my KYC expired and asked me to pay to unblock my account':
        'जैसे: एक कॉलर ने कहा कि मेरा KYC खत्म हो गया है और खाता अनब्लॉक करने के लिए पैसे भेजने को कहा',
    'I declare this information is true. A false complaint is punishable (BNS sections 217 and 248).':
        'मैं घोषणा करता/करती हूँ कि यह जानकारी सही है। झूठी शिकायत करना दंडनीय है (BNS धारा 217 और 248)।',
    'Tracing your money…': 'आपके पैसे का पता लगाया जा रहा है…',
    'Submit complaint': 'शिकायत दर्ज करें',
    'Complaint registered': 'शिकायत दर्ज हो गई',
    'Acknowledgement number': 'पावती संख्या',
    'Your complaint has been sent to the cyber police and is under investigation. Keep this acknowledgement number. You will get a notice in this app when money is returned to your account.':
        'आपकी शिकायत साइबर पुलिस को भेज दी गई है और इसकी जाँच चल रही है। यह पावती संख्या संभाल कर रखें। '
            'पैसा आपके खाते में वापस आने पर आपको इस ऐप में सूचना मिलेगी।',
    'Money returned': 'पैसा वापस मिला',
    'Under investigation': 'जाँच जारी है',
    'Amount reported': 'शिकायत की गई राशि',
    'Payment UTR': 'भुगतान UTR',
    'Returned to you': 'आपको वापस मिला',
    'My fraud complaints': 'मेरी धोखाधड़ी शिकायतें',
    'No complaints. To report a payment, open it in your history and tap "Report fraud".':
        'कोई शिकायत नहीं। किसी भुगतान की शिकायत करने के लिए उसे अपनी हिस्ट्री में खोलें और "धोखाधड़ी की शिकायत" पर टैप करें।',
    'Notices': 'सूचनाएँ',
    'No notices': 'कोई सूचना नहीं',
    'This account is on the mule list': 'यह खाता म्यूल सूची में है',
    'Cancel payment': 'भुगतान रद्द करें',
    'Pay anyway (repayment)': 'फिर भी भुगतान करें (पैसे लौटाने हेतु)',

    // complaint categories (sent by the server)
    'UPI / payment fraud': 'UPI / भुगतान धोखाधड़ी',
    'Fake KYC / bank call': 'नकली KYC / बैंक कॉल',
    'Investment / trading scam': 'निवेश / ट्रेडिंग घोटाला',
    'Job / task scam': 'नौकरी / टास्क घोटाला',
    'Online shopping fraud': 'ऑनलाइन शॉपिंग धोखाधड़ी',
    'Sextortion / blackmail': 'सेक्सटॉर्शन / ब्लैकमेल',
    'Other': 'अन्य',

    // notice titles (sent by the server)
    'Payment linked to a fraud complaint': 'भुगतान एक धोखाधड़ी शिकायत से जुड़ा है',
    'Your account is on the mule list': 'आपका खाता म्यूल सूची में है',
    'Court order: frozen crypto to be seized': 'कोर्ट का आदेश: फ़्रीज़ किया गया क्रिप्टो ज़ब्त होगा',
    'Court-approved recovery lien': 'कोर्ट द्वारा मंज़ूर वसूली लियन',
    'Money returned to you': 'आपका पैसा वापस मिल गया',
    'Removed from the mule list': 'म्यूल सूची से हटाया गया',
    'Services restored with conditions': 'शर्तों के साथ सेवाएँ फिर से शुरू',
    'Confirmed as a money mule': 'मनी म्यूल होने की पुष्टि हुई',
    'Branch verification submitted': 'शाखा सत्यापन जमा किया गया',

    // ---------------------------------------------------------------- location
    'Location is mandatory': 'लोकेशन ज़रूरी है',
    'Location (GPS) is turned off on this phone. Turn it on to make payments.':
        'इस फ़ोन में लोकेशन (GPS) बंद है। भुगतान करने के लिए इसे चालू करें।',
    'Turn on location': 'लोकेशन चालू करें',
    'This app needs permission to use your location. Tap Allow when Android asks.':
        'इस ऐप को आपकी लोकेशन इस्तेमाल करने की अनुमति चाहिए। Android पूछे तो Allow पर टैप करें।',
    'Allow location': 'लोकेशन की अनुमति दें',
    'Location permission is blocked for this app. Open App settings > Permissions > Location and choose Allow.':
        'इस ऐप के लिए लोकेशन की अनुमति बंद है। App settings > Permissions > Location खोलें और Allow चुनें।',
    'Open app settings': 'ऐप सेटिंग्स खोलें',
    'Could not find your location. Move near a window or outdoors and try again.':
        'आपकी लोकेशन नहीं मिल पाई। खिड़की के पास या बाहर जाकर फिर से कोशिश करें।',
    'Every payment records where it was made, so that money stolen by fraudsters can be traced. The payment has not been made.':
        'हर भुगतान के साथ यह दर्ज होता है कि वह कहाँ से किया गया, ताकि धोखेबाज़ों द्वारा चुराए गए पैसे का पता लगाया जा सके। '
            'भुगतान नहीं हुआ है।',

    // ---------------------------------------------------------------- settings
    'Settings': 'सेटिंग्स',
    'Night mode': 'नाइट मोड',
    'Auto': 'ऑटो',
    'Day': 'दिन',
    'Night': 'रात',
    "Auto follows the phone's dark theme setting.": 'ऑटो चुनने पर फ़ोन की डार्क थीम सेटिंग लागू होती है।',
    'Language': 'भाषा',
    'Location': 'लोकेशन',
    'Location is mandatory for payments. Every payment records where the phone was, so that money stolen by fraudsters can be traced.':
        'भुगतान के लिए लोकेशन ज़रूरी है। हर भुगतान के साथ यह दर्ज होता है कि फ़ोन कहाँ था, '
            'ताकि धोखेबाज़ों द्वारा चुराए गए पैसे का पता लगाया जा सके।',
    'Location allowed': 'लोकेशन की अनुमति है',
    'Location (GPS) is turned off': 'लोकेशन (GPS) बंद है',
    'Location permission not given': 'लोकेशन की अनुमति नहीं दी गई',
    'Location not available': 'लोकेशन उपलब्ध नहीं है',
    'Allow': 'अनुमति दें',
    'Server address': 'सर्वर का पता',
    'The computer running the RakshakPay server, e.g. https://rakshakpay.onrender.com':
        'वह कंप्यूटर जिस पर RakshakPay सर्वर चल रहा है, जैसे https://rakshakpay.onrender.com',
    'Save & test': 'सेव करें और जाँचें',
    'Checking…': 'जाँच हो रही है…',
    'Connected to RakshakPay server': 'RakshakPay सर्वर से जुड़ गया',
    'Cannot reach the RakshakPay server at {url}. Check your internet connection and the server address in Settings.':
        'RakshakPay सर्वर {url} से संपर्क नहीं हो पा रहा। अपना इंटरनेट कनेक्शन और सेटिंग्स में सर्वर का पता जाँचें।',

    // ---------------------------------------------------------------- bank slogans
    'Strong like the Western Ghats': 'पश्चिमी घाट जैसा मज़बूत',
    'Flowing with trust': 'भरोसे की धारा',
    'Nurturing every rupee': 'हर रुपये की देखभाल',
    'Banking at the heart of India': 'भारत के दिल में बैंकिंग',
    'Deep roots, wide reach': 'गहरी जड़ें, दूर तक पहुँच',

    // ---------------------------------------------------------------- server errors
    'Something went wrong. Please try again.': 'कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।',
    'Please log in again': 'कृपया फिर से लॉग इन करें',
    'Amount must be more than zero': 'राशि शून्य से ज़्यादा होनी चाहिए',
    'Insufficient balance. Available': 'खाते में पर्याप्त बैलेंस नहीं है। उपलब्ध',
    'Bank not found': 'बैंक नहीं मिला',
    'Business / shop name is required for a current (merchant) account':
        'चालू (व्यापारी) खाते के लिए व्यवसाय / दुकान का नाम ज़रूरी है',
    'Account opening blocked: this PAN is linked to a cyber fraud case. Visit the branch with original documents.':
        'खाता खोलना रोका गया: यह PAN एक साइबर धोखाधड़ी मामले से जुड़ा है। मूल दस्तावेज़ों के साथ शाखा में आएँ।',
    'This mobile number is already registered with another customer':
        'यह मोबाइल नंबर पहले से किसी दूसरे ग्राहक के नाम पर रजिस्टर्ड है',
    'Wrong Customer ID / mobile or password': 'गलत कस्टमर ID / मोबाइल या पासवर्ड',
    'Wrong MPIN': 'गलत MPIN',
    'Account not found': 'खाता नहीं मिला',
    'The new one must be different from the current one': 'नया, मौजूदा से अलग होना चाहिए',
    'Current password is wrong': 'मौजूदा पासवर्ड गलत है',
    'Current MPIN is wrong': 'मौजूदा MPIN गलत है',
    'Current ATM PIN is wrong': 'मौजूदा ATM PIN गलत है',
    'Current PIN is wrong': 'मौजूदा PIN गलत है',
    'Current passcode is wrong': 'मौजूदा पासकोड गलत है',
    'Current UPI PIN is wrong': 'मौजूदा UPI PIN गलत है',
    'No account found with this account number and IFSC': 'इस खाता संख्या और IFSC से कोई खाता नहीं मिला',
    'Transaction not found in your account': 'यह लेन-देन आपके खाते में नहीं मिला',
    'Only payments to another account can be reported here':
        'यहाँ सिर्फ़ किसी दूसरे खाते में किए गए भुगतान की शिकायत की जा सकती है',
    'A complaint for this transaction is already registered': 'इस लेन-देन की शिकायत पहले से दर्ज है',
    'This transaction is too old to report here. Please visit the police station.':
        'यह लेन-देन बहुत पुराना है, इसकी शिकायत यहाँ नहीं हो सकती। कृपया पुलिस स्टेशन जाएँ।',
    'Choose a complaint category': 'शिकायत की श्रेणी चुनें',
    'KYC rejected: this PAN is linked to a cyber fraud case': 'KYC अस्वीकार: यह PAN एक साइबर धोखाधड़ी मामले से जुड़ा है',
    'A CoinVault account already exists for this PAN. Please log in.':
        'इस PAN पर पहले से एक CoinVault खाता है। कृपया लॉग इन करें।',
    'This mobile number is already registered. Please log in.': 'यह मोबाइल नंबर पहले से रजिस्टर्ड है। कृपया लॉग इन करें।',
    'Bank account not found. Check the account number and IFSC.': 'बैंक खाता नहीं मिला। खाता संख्या और IFSC जाँचें।',
    'KYC failed: this bank account does not belong to this PAN': 'KYC विफल: यह बैंक खाता इस PAN का नहीं है',
    'Wrong mobile number or PIN': 'गलत मोबाइल नंबर या PIN',
    'Account frozen: this PAN is linked to a cyber fraud case': 'खाता फ़्रीज़: यह PAN एक साइबर धोखाधड़ी मामले से जुड़ा है',
    'New PIN must be exactly 4 digits': 'नया PIN ठीक 4 अंकों का होना चाहिए',
    'Wrong PIN': 'गलत PIN',
    'Unknown coin': 'अज्ञात कॉइन',
    'Amount too small to sell': 'बेचने के लिए राशि बहुत कम है',
    'Location is mandatory for payments. Turn on location (GPS) on your phone and allow the app to use it, then try again.':
        'भुगतान के लिए लोकेशन ज़रूरी है। अपने फ़ोन में लोकेशन (GPS) चालू करें और ऐप को इसका इस्तेमाल करने की अनुमति दें, '
            'फिर से कोशिश करें।',
    'Debit services are blocked on this account. Please visit your home branch for verification.':
        'इस खाते पर डेबिट सेवाएँ रोक दी गई हैं। सत्यापन के लिए कृपया अपनी होम ब्रांच जाएँ।',
    'Incorrect transaction PIN': 'गलत ट्रांज़ैक्शन PIN',
    'Account number and IFSC do not match any account': 'खाता संख्या और IFSC किसी भी खाते से मेल नहीं खाते',
    'You cannot transfer to the same account': 'आप उसी खाते में पैसे ट्रांसफ़र नहीं कर सकते',
    'Mode must be IMPS or NEFT': 'मोड IMPS या NEFT होना चाहिए',
    'ATM not found': 'ATM नहीं मिला',
    'Invalid card or PIN': 'गलत कार्ड या PIN',
    'This card is blocked': 'यह कार्ड ब्लॉक है',
    'Amount must be in multiples of ₹100': 'राशि ₹100 के गुणकों में होनी चाहिए',
    'Wrong mobile number or passcode': 'गलत मोबाइल नंबर या पासकोड',
    'Debit card details do not match': 'डेबिट कार्ड की जानकारी मेल नहीं खाती',
    'Wrong passcode': 'गलत पासकोड',
    'No account with your mobile number found': 'आपके मोबाइल नंबर से कोई खाता नहीं मिला',
    'This account is already linked to UPI': 'यह खाता पहले से UPI से जुड़ा है',
    'Your debit card is blocked. Unblock it in your bank app first.':
        'आपका डेबिट कार्ड ब्लॉक है। पहले अपने बैंक ऐप में इसे अनब्लॉक करें।',
    'This mobile number is not on UPI': 'यह मोबाइल नंबर UPI पर नहीं है',
    'UPI ID not found': 'UPI ID नहीं मिली',
    'This UPI ID is not linked to your profile': 'यह UPI ID आपकी प्रोफ़ाइल से जुड़ी नहीं है',
    'Incorrect UPI PIN': 'गलत UPI PIN',
    'You cannot pay the same account': 'आप उसी खाते में भुगतान नहीं कर सकते',
    'This account is on the national mule list: it has been used in cyber fraud. Money you send will be held to repay fraud victims and cannot be reversed. Pay only if you are repaying a victim on behalf of this person.':
        'यह खाता राष्ट्रीय म्यूल सूची में है: इसका इस्तेमाल साइबर धोखाधड़ी में हुआ है। आप जो पैसा भेजेंगे, वह धोखाधड़ी के '
            'पीड़ितों को लौटाने के लिए रोक लिया जाएगा और वापस नहीं होगा। भुगतान तभी करें जब आप इस व्यक्ति की ओर से '
            'किसी पीड़ित को पैसा लौटा रहे हों।',
    'Wrong staff ID or password for this bank': 'इस बैंक के लिए गलत स्टाफ़ ID या पासवर्ड',
    'Wrong badge ID or password': 'गलत बैज ID या पासवर्ड',
    'Complaint not found': 'शिकायत नहीं मिली',
    'Already decided': 'पहले ही फ़ैसला हो चुका है',
    'Customer not found in your bank': 'आपके बैंक में ग्राहक नहीं मिला',
    'Account not found in your bank': 'आपके बैंक में खाता नहीं मिला',
    'Type at least 3 characters': 'कम से कम 3 अक्षर लिखें',

    // form errors (shown after the field name, e.g. "Mobile: …")
    'Name can contain only letters, spaces and dots': 'नाम में सिर्फ़ अक्षर, स्पेस और बिंदु (.) हो सकते हैं',
    'Account holder must be at least 18 years old': 'खाताधारक की उम्र कम से कम 18 साल होनी चाहिए',
    'Enter a valid 10-digit Indian mobile number': 'सही 10 अंकों का भारतीय मोबाइल नंबर डालें',
    'PAN must look like ABCDE1234F': 'PAN इस तरह होना चाहिए: ABCDE1234F',
    'Aadhaar must be 12 digits and cannot start with 0 or 1': 'आधार 12 अंकों का होना चाहिए और 0 या 1 से शुरू नहीं हो सकता',
    'Enter a valid 6-digit PIN code': 'सही 6 अंकों का पिन कोड डालें',
    'Account type must be SAVINGS or CURRENT': 'खाते का प्रकार SAVINGS या CURRENT होना चाहिए',
    'PIN must be exactly 4 digits': 'PIN ठीक 4 अंकों का होना चाहिए',
    'PIN must be 4 digits': 'PIN 4 अंकों का होना चाहिए',
    'Wallet address can contain only letters and numbers': 'वॉलेट पते में सिर्फ़ अक्षर और अंक हो सकते हैं',
  },
  'kn': {
    // ---------------------------------------------------------------- app lock
    'Welcome back': 'ಮತ್ತೆ ಸ್ವಾಗತ',
    'Welcome back, {name}': 'ಮತ್ತೆ ಸ್ವಾಗತ, {name}',
    'Log out / switch user': 'ಲಾಗ್ ಔಟ್ / ಬಳಕೆದಾರರನ್ನು ಬದಲಿಸಿ',
    'Too many wrong attempts. Please log in again.': 'ತುಂಬಾ ಬಾರಿ ತಪ್ಪು ಪ್ರಯತ್ನ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಲಾಗಿನ್ ಮಾಡಿ.',
    '{message}. {count} tries left.': '{message}. ಇನ್ನೂ {count} ಪ್ರಯತ್ನಗಳು ಉಳಿದಿವೆ.',
    'Enter your 4-digit MPIN': 'ನಿಮ್ಮ 4 ಅಂಕಿಯ MPIN ನಮೂದಿಸಿ',
    'Enter your 4-digit passcode': 'ನಿಮ್ಮ 4 ಅಂಕಿಯ ಪಾಸ್‌ಕೋಡ್ ನಮೂದಿಸಿ',
    'Enter your RakshakPay passcode': 'ನಿಮ್ಮ RakshakPay ಪಾಸ್‌ಕೋಡ್ ನಮೂದಿಸಿ',
    'Enter your 4-digit CoinVault PIN': 'ನಿಮ್ಮ 4 ಅಂಕಿಯ CoinVault PIN ನಮೂದಿಸಿ',

    // ---------------------------------------------------------------- PIN dialog, common buttons
    'Enter 4-digit PIN': '4 ಅಂಕಿಯ PIN ನಮೂದಿಸಿ',
    'Enter UPI PIN': 'UPI PIN ನಮೂದಿಸಿ',
    'Enter CoinVault PIN': 'CoinVault PIN ನಮೂದಿಸಿ',
    'Pay {amount}': '{amount} ಪಾವತಿಸಿ',
    'Cancel': 'ರದ್ದುಮಾಡಿ',
    'Confirm': 'ದೃಢೀಕರಿಸಿ',
    'Done': 'ಮುಗಿಯಿತು',
    'Try again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',

    // ---------------------------------------------------------------- account status
    'Active': 'ಸಕ್ರಿಯ',
    'Under verification': 'ಪರಿಶೀಲನೆಯಲ್ಲಿದೆ',
    'Blocked – fraud': 'ಬ್ಲಾಕ್ – ವಂಚನೆ',
    'Current (Merchant)': 'ಚಾಲ್ತಿ (ವ್ಯಾಪಾರಿ)',
    'Savings': 'ಉಳಿತಾಯ',

    // ---------------------------------------------------------------- change password / PIN
    'password': 'ಪಾಸ್‌ವರ್ಡ್',
    'passcode': 'ಪಾಸ್‌ಕೋಡ್',
    'Enter {count} digits': '{count} ಅಂಕಿಗಳನ್ನು ನಮೂದಿಸಿ',
    'At least 6 characters': 'ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳು',
    'Must be different from the current {what}': 'ಈಗಿನ {what} ಗಿಂತ ಬೇರೆಯಾಗಿರಬೇಕು',
    'Too easy to guess (all the same digit)': 'ಊಹಿಸಲು ತುಂಬಾ ಸುಲಭ (ಎಲ್ಲಾ ಅಂಕಿಗಳು ಒಂದೇ)',
    'Too easy to guess (a sequence)': 'ಊಹಿಸಲು ತುಂಬಾ ಸುಲಭ (ಸರಣಿ ಅಂಕಿಗಳು)',
    '{what} changed': '{what} ಬದಲಾಯಿಸಲಾಗಿದೆ',
    'Current {what}': 'ಈಗಿನ {what}',
    'Required': 'ಅಗತ್ಯವಿದೆ',
    'New {what}': 'ಹೊಸ {what}',
    'Confirm new {what}': 'ಹೊಸ {what} ಮತ್ತೊಮ್ಮೆ ನಮೂದಿಸಿ',
    'Does not match': 'ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
    'Saving…': 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…',
    'Change {what}': '{what} ಬದಲಾಯಿಸಿ',
    'Never share your {what} with anyone, including callers who say they are from the bank, police or RBI.':
        'ನಿಮ್ಮ {what} ಅನ್ನು ಯಾರೊಂದಿಗೂ ಹಂಚಿಕೊಳ್ಳಬೇಡಿ, ಬ್ಯಾಂಕ್, ಪೊಲೀಸ್ ಅಥವಾ RBI ಇಂದ ಕರೆ ಮಾಡುತ್ತಿದ್ದೇವೆ ಎನ್ನುವವರೊಂದಿಗೂ ಸಹ.',

    // ---------------------------------------------------------------- fraud complaints
    'Report fraud (1930)': 'ವಂಚನೆ ವರದಿ ಮಾಡಿ (1930)',
    '{amount} paid to {name}': '{name} ಅವರಿಗೆ {amount} ಪಾವತಿಸಲಾಗಿದೆ',
    'UTR': 'UTR',
    "Report as soon as possible: money that is still in the fraudster's accounts can be held only before it is withdrawn.":
        'ಆದಷ್ಟು ಬೇಗ ದೂರು ನೀಡಿ: ವಂಚಕರ ಖಾತೆಗಳಲ್ಲಿ ಇನ್ನೂ ಇರುವ ಹಣವನ್ನು ಅದನ್ನು ಹಿಂಪಡೆಯುವ ಮೊದಲೇ ತಡೆಹಿಡಿಯಬಹುದು.',
    'What happened?': 'ಏನಾಯಿತು?',
    'Choose what happened': 'ಏನಾಯಿತು ಎಂದು ಆಯ್ಕೆಮಾಡಿ',
    'Please confirm the declaration': 'ದಯವಿಟ್ಟು ಘೋಷಣೆಯನ್ನು ದೃಢೀಕರಿಸಿ',
    'Describe what happened (optional)': 'ಏನಾಯಿತು ಎಂದು ವಿವರಿಸಿ (ಐಚ್ಛಿಕ)',
    'e.g. A caller said my KYC expired and asked me to pay to unblock my account':
        'ಉದಾ: ನನ್ನ KYC ಅವಧಿ ಮುಗಿದಿದೆ ಎಂದು ಕರೆ ಮಾಡಿದವರು ಹೇಳಿ, ಖಾತೆ ಅನ್‌ಬ್ಲಾಕ್ ಮಾಡಲು ಹಣ ಪಾವತಿಸಲು ಹೇಳಿದರು',
    'I declare this information is true. A false complaint is punishable (BNS sections 217 and 248).':
        'ಈ ಮಾಹಿತಿ ಸತ್ಯ ಎಂದು ನಾನು ಘೋಷಿಸುತ್ತೇನೆ. ಸುಳ್ಳು ದೂರು ನೀಡುವುದು ಶಿಕ್ಷಾರ್ಹ ಅಪರಾಧ (BNS ಸೆಕ್ಷನ್ 217 ಮತ್ತು 248).',
    'Tracing your money…': 'ನಿಮ್ಮ ಹಣವನ್ನು ಪತ್ತೆ ಮಾಡಲಾಗುತ್ತಿದೆ…',
    'Submit complaint': 'ದೂರು ಸಲ್ಲಿಸಿ',
    'Complaint registered': 'ದೂರು ದಾಖಲಾಗಿದೆ',
    'Acknowledgement number': 'ಸ್ವೀಕೃತಿ ಸಂಖ್ಯೆ',
    'Your complaint has been sent to the cyber police and is under investigation. Keep this acknowledgement number. You will get a notice in this app when money is returned to your account.':
        'ನಿಮ್ಮ ದೂರನ್ನು ಸೈಬರ್ ಪೊಲೀಸರಿಗೆ ಕಳುಹಿಸಲಾಗಿದೆ ಮತ್ತು ತನಿಖೆ ನಡೆಯುತ್ತಿದೆ. ಈ ಸ್ವೀಕೃತಿ ಸಂಖ್ಯೆಯನ್ನು ಜೋಪಾನವಾಗಿಡಿ. '
            'ಹಣ ನಿಮ್ಮ ಖಾತೆಗೆ ಮರಳಿ ಬಂದಾಗ ಈ ಆ್ಯಪ್‌ನಲ್ಲಿ ಸೂಚನೆ ಬರುತ್ತದೆ.',
    'Money returned': 'ಹಣ ಮರಳಿಸಲಾಗಿದೆ',
    'Under investigation': 'ತನಿಖೆಯಲ್ಲಿದೆ',
    'Amount reported': 'ದೂರು ನೀಡಿದ ಮೊತ್ತ',
    'Payment UTR': 'ಪಾವತಿ UTR',
    'Returned to you': 'ನಿಮಗೆ ಮರಳಿಸಿದ್ದು',
    'My fraud complaints': 'ನನ್ನ ವಂಚನೆ ದೂರುಗಳು',
    'No complaints. To report a payment, open it in your history and tap "Report fraud".':
        'ಯಾವುದೇ ದೂರುಗಳಿಲ್ಲ. ಪಾವತಿಯ ಬಗ್ಗೆ ದೂರು ನೀಡಲು, ಅದನ್ನು ನಿಮ್ಮ ಇತಿಹಾಸದಲ್ಲಿ ತೆರೆದು "ವಂಚನೆ ವರದಿ ಮಾಡಿ" ಒತ್ತಿರಿ.',
    'Notices': 'ಸೂಚನೆಗಳು',
    'No notices': 'ಯಾವುದೇ ಸೂಚನೆಗಳಿಲ್ಲ',
    'This account is on the mule list': 'ಈ ಖಾತೆ ಮ್ಯೂಲ್ ಪಟ್ಟಿಯಲ್ಲಿದೆ',
    'Cancel payment': 'ಪಾವತಿ ರದ್ದುಮಾಡಿ',
    'Pay anyway (repayment)': 'ಆದರೂ ಪಾವತಿಸಿ (ಮರುಪಾವತಿ)',

    // complaint categories (sent by the server)
    'UPI / payment fraud': 'UPI / ಪಾವತಿ ವಂಚನೆ',
    'Fake KYC / bank call': 'ನಕಲಿ KYC / ಬ್ಯಾಂಕ್ ಕರೆ',
    'Investment / trading scam': 'ಹೂಡಿಕೆ / ಟ್ರೇಡಿಂಗ್ ವಂಚನೆ',
    'Job / task scam': 'ಉದ್ಯೋಗ / ಟಾಸ್ಕ್ ವಂಚನೆ',
    'Online shopping fraud': 'ಆನ್‌ಲೈನ್ ಶಾಪಿಂಗ್ ವಂಚನೆ',
    'Sextortion / blackmail': 'ಸೆಕ್ಸ್‌ಟಾರ್ಷನ್ / ಬ್ಲ್ಯಾಕ್‌ಮೇಲ್',
    'Other': 'ಇತರೆ',

    // notice titles (sent by the server)
    'Payment linked to a fraud complaint': 'ಪಾವತಿಯು ವಂಚನೆ ದೂರಿಗೆ ಸಂಬಂಧಿಸಿದೆ',
    'Your account is on the mule list': 'ನಿಮ್ಮ ಖಾತೆ ಮ್ಯೂಲ್ ಪಟ್ಟಿಯಲ್ಲಿದೆ',
    'Court order: frozen crypto to be seized': 'ನ್ಯಾಯಾಲಯದ ಆದೇಶ: ಸ್ಥಗಿತಗೊಳಿಸಿದ ಕ್ರಿಪ್ಟೋ ಜಪ್ತಿ ಮಾಡಲಾಗುವುದು',
    'Court-approved recovery lien': 'ನ್ಯಾಯಾಲಯ ಅನುಮೋದಿತ ವಸೂಲಾತಿ ಲೀನ್',
    'Money returned to you': 'ನಿಮ್ಮ ಹಣ ಮರಳಿ ಬಂದಿದೆ',
    'Removed from the mule list': 'ಮ್ಯೂಲ್ ಪಟ್ಟಿಯಿಂದ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
    'Services restored with conditions': 'ಷರತ್ತುಗಳೊಂದಿಗೆ ಸೇವೆಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ',
    'Confirmed as a money mule': 'ಮನಿ ಮ್ಯೂಲ್ ಎಂದು ದೃಢಪಟ್ಟಿದೆ',
    'Branch verification submitted': 'ಶಾಖೆಯ ಪರಿಶೀಲನೆ ಸಲ್ಲಿಸಲಾಗಿದೆ',

    // ---------------------------------------------------------------- location
    'Location is mandatory': 'ಲೊಕೇಶನ್ ಕಡ್ಡಾಯ',
    'Location (GPS) is turned off on this phone. Turn it on to make payments.':
        'ಈ ಫೋನ್‌ನಲ್ಲಿ ಲೊಕೇಶನ್ (GPS) ಆಫ್ ಆಗಿದೆ. ಪಾವತಿ ಮಾಡಲು ಅದನ್ನು ಆನ್ ಮಾಡಿ.',
    'Turn on location': 'ಲೊಕೇಶನ್ ಆನ್ ಮಾಡಿ',
    'This app needs permission to use your location. Tap Allow when Android asks.':
        'ಈ ಆ್ಯಪ್‌ಗೆ ನಿಮ್ಮ ಲೊಕೇಶನ್ ಬಳಸಲು ಅನುಮತಿ ಬೇಕು. Android ಕೇಳಿದಾಗ Allow ಒತ್ತಿರಿ.',
    'Allow location': 'ಲೊಕೇಶನ್‌ಗೆ ಅನುಮತಿ ನೀಡಿ',
    'Location permission is blocked for this app. Open App settings > Permissions > Location and choose Allow.':
        'ಈ ಆ್ಯಪ್‌ಗೆ ಲೊಕೇಶನ್ ಅನುಮತಿಯನ್ನು ತಡೆಹಿಡಿಯಲಾಗಿದೆ. App settings > Permissions > Location ತೆರೆದು Allow ಆಯ್ಕೆಮಾಡಿ.',
    'Open app settings': 'ಆ್ಯಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಿರಿ',
    'Could not find your location. Move near a window or outdoors and try again.':
        'ನಿಮ್ಮ ಲೊಕೇಶನ್ ಸಿಗಲಿಲ್ಲ. ಕಿಟಕಿಯ ಬಳಿ ಅಥವಾ ಹೊರಗೆ ಹೋಗಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    'Every payment records where it was made, so that money stolen by fraudsters can be traced. The payment has not been made.':
        'ವಂಚಕರು ಕದ್ದ ಹಣವನ್ನು ಪತ್ತೆ ಮಾಡಲು, ಪ್ರತಿ ಪಾವತಿಯನ್ನು ಎಲ್ಲಿಂದ ಮಾಡಲಾಯಿತು ಎಂದು ದಾಖಲಿಸಲಾಗುತ್ತದೆ. ಪಾವತಿ ಆಗಿಲ್ಲ.',

    // ---------------------------------------------------------------- settings
    'Settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
    'Night mode': 'ನೈಟ್ ಮೋಡ್',
    'Auto': 'ಆಟೋ',
    'Day': 'ಹಗಲು',
    'Night': 'ರಾತ್ರಿ',
    "Auto follows the phone's dark theme setting.": 'ಆಟೋ ಆಯ್ಕೆಯು ಫೋನ್‌ನ ಡಾರ್ಕ್ ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್ ಅನುಸರಿಸುತ್ತದೆ.',
    'Language': 'ಭಾಷೆ',
    'Location': 'ಲೊಕೇಶನ್',
    'Location is mandatory for payments. Every payment records where the phone was, so that money stolen by fraudsters can be traced.':
        'ಪಾವತಿಗಳಿಗೆ ಲೊಕೇಶನ್ ಕಡ್ಡಾಯ. ವಂಚಕರು ಕದ್ದ ಹಣವನ್ನು ಪತ್ತೆ ಮಾಡಲು, ಪ್ರತಿ ಪಾವತಿಯ ವೇಳೆ ಫೋನ್ ಎಲ್ಲಿತ್ತು ಎಂದು '
            'ದಾಖಲಿಸಲಾಗುತ್ತದೆ.',
    'Location allowed': 'ಲೊಕೇಶನ್‌ಗೆ ಅನುಮತಿ ಇದೆ',
    'Location (GPS) is turned off': 'ಲೊಕೇಶನ್ (GPS) ಆಫ್ ಆಗಿದೆ',
    'Location permission not given': 'ಲೊಕೇಶನ್ ಅನುಮತಿ ನೀಡಿಲ್ಲ',
    'Location not available': 'ಲೊಕೇಶನ್ ಲಭ್ಯವಿಲ್ಲ',
    'Allow': 'ಅನುಮತಿಸಿ',
    'Server address': 'ಸರ್ವರ್ ವಿಳಾಸ',
    'The computer running the RakshakPay server, e.g. https://rakshakpay.onrender.com':
        'RakshakPay ಸರ್ವರ್ ಚಾಲನೆಯಲ್ಲಿರುವ ಕಂಪ್ಯೂಟರ್, ಉದಾ: https://rakshakpay.onrender.com',
    'Save & test': 'ಉಳಿಸಿ ಮತ್ತು ಪರೀಕ್ಷಿಸಿ',
    'Checking…': 'ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ…',
    'Connected to RakshakPay server': 'RakshakPay ಸರ್ವರ್‌ಗೆ ಸಂಪರ್ಕಗೊಂಡಿದೆ',
    'Cannot reach the RakshakPay server at {url}. Check your internet connection and the server address in Settings.':
        'RakshakPay ಸರ್ವರ್ {url} ಅನ್ನು ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಮತ್ತು ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿರುವ '
            'ಸರ್ವರ್ ವಿಳಾಸವನ್ನು ಪರಿಶೀಲಿಸಿ.',

    // ---------------------------------------------------------------- bank slogans
    'Strong like the Western Ghats': 'ಪಶ್ಚಿಮ ಘಟ್ಟಗಳಂತೆ ಬಲಿಷ್ಠ',
    'Flowing with trust': 'ನಂಬಿಕೆಯ ಹರಿವು',
    'Nurturing every rupee': 'ಪ್ರತಿ ರೂಪಾಯಿಯ ಪೋಷಣೆ',
    'Banking at the heart of India': 'ಭಾರತದ ಹೃದಯದಲ್ಲಿ ಬ್ಯಾಂಕಿಂಗ್',
    'Deep roots, wide reach': 'ಆಳವಾದ ಬೇರುಗಳು, ವಿಶಾಲ ವ್ಯಾಪ್ತಿ',

    // ---------------------------------------------------------------- server errors
    'Something went wrong. Please try again.': 'ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    'Please log in again': 'ದಯವಿಟ್ಟು ಮತ್ತೆ ಲಾಗಿನ್ ಮಾಡಿ',
    'Amount must be more than zero': 'ಮೊತ್ತ ಸೊನ್ನೆಗಿಂತ ಹೆಚ್ಚಾಗಿರಬೇಕು',
    'Insufficient balance. Available': 'ಸಾಕಷ್ಟು ಬ್ಯಾಲೆನ್ಸ್ ಇಲ್ಲ. ಲಭ್ಯವಿರುವುದು',
    'Bank not found': 'ಬ್ಯಾಂಕ್ ಸಿಗಲಿಲ್ಲ',
    'Business / shop name is required for a current (merchant) account':
        'ಚಾಲ್ತಿ (ವ್ಯಾಪಾರಿ) ಖಾತೆಗೆ ವ್ಯವಹಾರ / ಅಂಗಡಿಯ ಹೆಸರು ಅಗತ್ಯ',
    'Account opening blocked: this PAN is linked to a cyber fraud case. Visit the branch with original documents.':
        'ಖಾತೆ ತೆರೆಯುವುದನ್ನು ತಡೆಯಲಾಗಿದೆ: ಈ PAN ಸೈಬರ್ ವಂಚನೆ ಪ್ರಕರಣಕ್ಕೆ ಸಂಬಂಧಿಸಿದೆ. ಮೂಲ ದಾಖಲೆಗಳೊಂದಿಗೆ ಶಾಖೆಗೆ ಭೇಟಿ ನೀಡಿ.',
    'This mobile number is already registered with another customer':
        'ಈ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಈಗಾಗಲೇ ಬೇರೆ ಗ್ರಾಹಕರ ಹೆಸರಿನಲ್ಲಿ ನೋಂದಣಿಯಾಗಿದೆ',
    'Wrong Customer ID / mobile or password': 'ತಪ್ಪಾದ ಗ್ರಾಹಕ ID / ಮೊಬೈಲ್ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್',
    'Wrong MPIN': 'ತಪ್ಪಾದ MPIN',
    'Account not found': 'ಖಾತೆ ಸಿಗಲಿಲ್ಲ',
    'The new one must be different from the current one': 'ಹೊಸದು ಈಗಿನದಕ್ಕಿಂತ ಬೇರೆಯಾಗಿರಬೇಕು',
    'Current password is wrong': 'ಈಗಿನ ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ',
    'Current MPIN is wrong': 'ಈಗಿನ MPIN ತಪ್ಪಾಗಿದೆ',
    'Current ATM PIN is wrong': 'ಈಗಿನ ATM PIN ತಪ್ಪಾಗಿದೆ',
    'Current PIN is wrong': 'ಈಗಿನ PIN ತಪ್ಪಾಗಿದೆ',
    'Current passcode is wrong': 'ಈಗಿನ ಪಾಸ್‌ಕೋಡ್ ತಪ್ಪಾಗಿದೆ',
    'Current UPI PIN is wrong': 'ಈಗಿನ UPI PIN ತಪ್ಪಾಗಿದೆ',
    'No account found with this account number and IFSC': 'ಈ ಖಾತೆ ಸಂಖ್ಯೆ ಮತ್ತು IFSC ಯೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ಸಿಗಲಿಲ್ಲ',
    'Transaction not found in your account': 'ಈ ವಹಿವಾಟು ನಿಮ್ಮ ಖಾತೆಯಲ್ಲಿ ಸಿಗಲಿಲ್ಲ',
    'Only payments to another account can be reported here': 'ಇಲ್ಲಿ ಬೇರೆ ಖಾತೆಗೆ ಮಾಡಿದ ಪಾವತಿಗಳ ಬಗ್ಗೆ ಮಾತ್ರ ದೂರು ನೀಡಬಹುದು',
    'A complaint for this transaction is already registered': 'ಈ ವಹಿವಾಟಿನ ಬಗ್ಗೆ ಈಗಾಗಲೇ ದೂರು ದಾಖಲಾಗಿದೆ',
    'This transaction is too old to report here. Please visit the police station.':
        'ಈ ವಹಿವಾಟು ತುಂಬಾ ಹಳೆಯದು, ಇಲ್ಲಿ ದೂರು ನೀಡಲು ಸಾಧ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ಪೊಲೀಸ್ ಠಾಣೆಗೆ ಭೇಟಿ ನೀಡಿ.',
    'Choose a complaint category': 'ದೂರಿನ ವರ್ಗವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'KYC rejected: this PAN is linked to a cyber fraud case': 'KYC ತಿರಸ್ಕರಿಸಲಾಗಿದೆ: ಈ PAN ಸೈಬರ್ ವಂಚನೆ ಪ್ರಕರಣಕ್ಕೆ ಸಂಬಂಧಿಸಿದೆ',
    'A CoinVault account already exists for this PAN. Please log in.':
        'ಈ PAN ಗೆ ಈಗಾಗಲೇ CoinVault ಖಾತೆ ಇದೆ. ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.',
    'This mobile number is already registered. Please log in.': 'ಈ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಈಗಾಗಲೇ ನೋಂದಣಿಯಾಗಿದೆ. ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.',
    'Bank account not found. Check the account number and IFSC.': 'ಬ್ಯಾಂಕ್ ಖಾತೆ ಸಿಗಲಿಲ್ಲ. ಖಾತೆ ಸಂಖ್ಯೆ ಮತ್ತು IFSC ಪರಿಶೀಲಿಸಿ.',
    'KYC failed: this bank account does not belong to this PAN': 'KYC ವಿಫಲವಾಗಿದೆ: ಈ ಬ್ಯಾಂಕ್ ಖಾತೆ ಈ PAN ಗೆ ಸೇರಿಲ್ಲ',
    'Wrong mobile number or PIN': 'ತಪ್ಪಾದ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಅಥವಾ PIN',
    'Account frozen: this PAN is linked to a cyber fraud case': 'ಖಾತೆ ಸ್ಥಗಿತಗೊಳಿಸಲಾಗಿದೆ: ಈ PAN ಸೈಬರ್ ವಂಚನೆ ಪ್ರಕರಣಕ್ಕೆ ಸಂಬಂಧಿಸಿದೆ',
    'New PIN must be exactly 4 digits': 'ಹೊಸ PIN ನಿಖರವಾಗಿ 4 ಅಂಕಿಗಳಾಗಿರಬೇಕು',
    'Wrong PIN': 'ತಪ್ಪಾದ PIN',
    'Unknown coin': 'ಅಪರಿಚಿತ ಕಾಯಿನ್',
    'Amount too small to sell': 'ಮಾರಾಟ ಮಾಡಲು ಮೊತ್ತ ತುಂಬಾ ಕಡಿಮೆ',
    'Location is mandatory for payments. Turn on location (GPS) on your phone and allow the app to use it, then try again.':
        'ಪಾವತಿಗಳಿಗೆ ಲೊಕೇಶನ್ ಕಡ್ಡಾಯ. ನಿಮ್ಮ ಫೋನ್‌ನಲ್ಲಿ ಲೊಕೇಶನ್ (GPS) ಆನ್ ಮಾಡಿ, ಆ್ಯಪ್‌ಗೆ ಅದನ್ನು ಬಳಸಲು ಅನುಮತಿ ನೀಡಿ, '
            'ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    'Debit services are blocked on this account. Please visit your home branch for verification.':
        'ಈ ಖಾತೆಯಲ್ಲಿ ಡೆಬಿಟ್ ಸೇವೆಗಳನ್ನು ತಡೆಹಿಡಿಯಲಾಗಿದೆ. ಪರಿಶೀಲನೆಗಾಗಿ ದಯವಿಟ್ಟು ನಿಮ್ಮ ಹೋಮ್ ಬ್ರಾಂಚ್‌ಗೆ ಭೇಟಿ ನೀಡಿ.',
    'Incorrect transaction PIN': 'ತಪ್ಪಾದ ವಹಿವಾಟು PIN',
    'Account number and IFSC do not match any account': 'ಖಾತೆ ಸಂಖ್ಯೆ ಮತ್ತು IFSC ಯಾವುದೇ ಖಾತೆಗೆ ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
    'You cannot transfer to the same account': 'ಅದೇ ಖಾತೆಗೆ ವರ್ಗಾವಣೆ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ',
    'Mode must be IMPS or NEFT': 'ಮೋಡ್ IMPS ಅಥವಾ NEFT ಆಗಿರಬೇಕು',
    'ATM not found': 'ATM ಸಿಗಲಿಲ್ಲ',
    'Invalid card or PIN': 'ತಪ್ಪಾದ ಕಾರ್ಡ್ ಅಥವಾ PIN',
    'This card is blocked': 'ಈ ಕಾರ್ಡ್ ಬ್ಲಾಕ್ ಆಗಿದೆ',
    'Amount must be in multiples of ₹100': 'ಮೊತ್ತ ₹100 ರ ಗುಣಕಗಳಲ್ಲಿರಬೇಕು',
    'Wrong mobile number or passcode': 'ತಪ್ಪಾದ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಅಥವಾ ಪಾಸ್‌ಕೋಡ್',
    'Debit card details do not match': 'ಡೆಬಿಟ್ ಕಾರ್ಡ್ ವಿವರಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
    'Wrong passcode': 'ತಪ್ಪಾದ ಪಾಸ್‌ಕೋಡ್',
    'No account with your mobile number found': 'ನಿಮ್ಮ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ಸಿಗಲಿಲ್ಲ',
    'This account is already linked to UPI': 'ಈ ಖಾತೆ ಈಗಾಗಲೇ UPI ಗೆ ಲಿಂಕ್ ಆಗಿದೆ',
    'Your debit card is blocked. Unblock it in your bank app first.':
        'ನಿಮ್ಮ ಡೆಬಿಟ್ ಕಾರ್ಡ್ ಬ್ಲಾಕ್ ಆಗಿದೆ. ಮೊದಲು ನಿಮ್ಮ ಬ್ಯಾಂಕ್ ಆ್ಯಪ್‌ನಲ್ಲಿ ಅನ್‌ಬ್ಲಾಕ್ ಮಾಡಿ.',
    'This mobile number is not on UPI': 'ಈ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ UPI ನಲ್ಲಿ ಇಲ್ಲ',
    'UPI ID not found': 'UPI ID ಸಿಗಲಿಲ್ಲ',
    'This UPI ID is not linked to your profile': 'ಈ UPI ID ನಿಮ್ಮ ಪ್ರೊಫೈಲ್‌ಗೆ ಲಿಂಕ್ ಆಗಿಲ್ಲ',
    'Incorrect UPI PIN': 'ತಪ್ಪಾದ UPI PIN',
    'You cannot pay the same account': 'ಅದೇ ಖಾತೆಗೆ ಪಾವತಿಸಲು ಸಾಧ್ಯವಿಲ್ಲ',
    'This account is on the national mule list: it has been used in cyber fraud. Money you send will be held to repay fraud victims and cannot be reversed. Pay only if you are repaying a victim on behalf of this person.':
        'ಈ ಖಾತೆ ರಾಷ್ಟ್ರೀಯ ಮ್ಯೂಲ್ ಪಟ್ಟಿಯಲ್ಲಿದೆ: ಇದನ್ನು ಸೈಬರ್ ವಂಚನೆಗೆ ಬಳಸಲಾಗಿದೆ. ನೀವು ಕಳುಹಿಸುವ ಹಣವನ್ನು ವಂಚನೆಗೆ '
            'ಒಳಗಾದವರಿಗೆ ಮರುಪಾವತಿಸಲು ತಡೆಹಿಡಿಯಲಾಗುತ್ತದೆ ಮತ್ತು ಅದನ್ನು ಹಿಂಪಡೆಯಲು ಸಾಧ್ಯವಿಲ್ಲ. ಈ ವ್ಯಕ್ತಿಯ ಪರವಾಗಿ ವಂಚನೆಗೆ '
            'ಒಳಗಾದವರಿಗೆ ಹಣ ಮರುಪಾವತಿಸುತ್ತಿದ್ದರೆ ಮಾತ್ರ ಪಾವತಿಸಿ.',
    'Wrong staff ID or password for this bank': 'ಈ ಬ್ಯಾಂಕ್‌ಗೆ ತಪ್ಪಾದ ಸಿಬ್ಬಂದಿ ID ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್',
    'Wrong badge ID or password': 'ತಪ್ಪಾದ ಬ್ಯಾಡ್ಜ್ ID ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್',
    'Complaint not found': 'ದೂರು ಸಿಗಲಿಲ್ಲ',
    'Already decided': 'ಈಗಾಗಲೇ ನಿರ್ಧರಿಸಲಾಗಿದೆ',
    'Customer not found in your bank': 'ನಿಮ್ಮ ಬ್ಯಾಂಕ್‌ನಲ್ಲಿ ಗ್ರಾಹಕರು ಸಿಗಲಿಲ್ಲ',
    'Account not found in your bank': 'ನಿಮ್ಮ ಬ್ಯಾಂಕ್‌ನಲ್ಲಿ ಖಾತೆ ಸಿಗಲಿಲ್ಲ',
    'Type at least 3 characters': 'ಕನಿಷ್ಠ 3 ಅಕ್ಷರಗಳನ್ನು ಟೈಪ್ ಮಾಡಿ',

    // form errors (shown after the field name, e.g. "Mobile: …")
    'Name can contain only letters, spaces and dots': 'ಹೆಸರಿನಲ್ಲಿ ಅಕ್ಷರಗಳು, ಸ್ಪೇಸ್ ಮತ್ತು ಚುಕ್ಕೆಗಳು (.) ಮಾತ್ರ ಇರಬಹುದು',
    'Account holder must be at least 18 years old': 'ಖಾತೆದಾರರಿಗೆ ಕನಿಷ್ಠ 18 ವರ್ಷ ವಯಸ್ಸಾಗಿರಬೇಕು',
    'Enter a valid 10-digit Indian mobile number': 'ಸರಿಯಾದ 10 ಅಂಕಿಯ ಭಾರತೀಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ',
    'PAN must look like ABCDE1234F': 'PAN ಈ ರೀತಿ ಇರಬೇಕು: ABCDE1234F',
    'Aadhaar must be 12 digits and cannot start with 0 or 1': 'ಆಧಾರ್ 12 ಅಂಕಿಗಳಾಗಿರಬೇಕು ಮತ್ತು 0 ಅಥವಾ 1 ರಿಂದ ಆರಂಭವಾಗಬಾರದು',
    'Enter a valid 6-digit PIN code': 'ಸರಿಯಾದ 6 ಅಂಕಿಯ ಪಿನ್ ಕೋಡ್ ನಮೂದಿಸಿ',
    'Account type must be SAVINGS or CURRENT': 'ಖಾತೆಯ ಪ್ರಕಾರ SAVINGS ಅಥವಾ CURRENT ಆಗಿರಬೇಕು',
    'PIN must be exactly 4 digits': 'PIN ನಿಖರವಾಗಿ 4 ಅಂಕಿಗಳಾಗಿರಬೇಕು',
    'PIN must be 4 digits': 'PIN 4 ಅಂಕಿಗಳಾಗಿರಬೇಕು',
    'Wallet address can contain only letters and numbers': 'ವಾಲೆಟ್ ವಿಳಾಸದಲ್ಲಿ ಅಕ್ಷರಗಳು ಮತ್ತು ಅಂಕಿಗಳು ಮಾತ್ರ ಇರಬಹುದು',
  },
};
