package `in`.rakshakpay.upi_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Receives "upi://pay?..." links from other apps (e.g. CoinVault's Deposit button)
 * and hands them to Flutter, which opens the Pay screen.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = intent?.takeIf { it.action == Intent.ACTION_VIEW }?.dataString
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rakshakpay/upi_link").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(initialLink)
                    initialLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_VIEW) {
            intent.dataString?.let { channel?.invokeMethod("onLink", it) }
        }
    }
}
