package com.wishnesita.wish_nesita

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val iconChannel = "com.wishnesita/app_icon"

    // Mapeamento: id (usado pelo Flutter) → nome completo do alias
    private val aliases = mapOf(
        "default" to "com.wishnesita.wish_nesita.AliasDefault",
        "pink"    to "com.wishnesita.wish_nesita.AliasPink",
        "dark"    to "com.wishnesita.wish_nesita.AliasDark",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, iconChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val icon = call.argument<String>("icon") ?: "default"
                        if (!aliases.containsKey(icon)) {
                            result.error("INVALID_ICON", "Variante '$icon' não existe.", null)
                            return@setMethodCallHandler
                        }
                        setAppIcon(icon)
                        result.success(null)
                    }
                    "getActiveIcon" -> {
                        result.success(getActiveIcon())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setAppIcon(iconId: String) {
        val pm = packageManager
        aliases.forEach { (id, aliasName) ->
            val state = if (id == iconId)
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            pm.setComponentEnabledSetting(
                ComponentName(this, aliasName),
                state,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun getActiveIcon(): String {
        val pm = packageManager
        return aliases.entries.firstOrNull { (_, aliasName) ->
            pm.getComponentEnabledSetting(ComponentName(this, aliasName)) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        }?.key ?: "default"
    }
}
