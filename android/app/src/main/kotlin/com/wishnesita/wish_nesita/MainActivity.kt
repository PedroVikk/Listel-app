package com.wishnesita.wish_nesita

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val iconChannel = "com.wishnesita/app_icon"

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
                        try {
                            setAppIcon(icon)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SET_ICON_FAILED", e.message, null)
                        }
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

        // 1. Habilita o novo alias PRIMEIRO — garante que o launcher sempre
        //    tem pelo menos um alias ativo, mesmo se o app for morto no meio.
        pm.setComponentEnabledSetting(
            ComponentName(this, aliases[iconId]!!),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )

        // 2. Desabilita todos os outros.
        aliases.filter { it.key != iconId }.values.forEach { aliasName ->
            pm.setComponentEnabledSetting(
                ComponentName(this, aliasName),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun getActiveIcon(): String {
        val pm = packageManager
        // Procura alias explicitamente ENABLED (após primeira troca).
        aliases.entries.firstOrNull { (_, aliasName) ->
            pm.getComponentEnabledSetting(ComponentName(this, aliasName)) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        }?.let { return it.key }

        // Antes da primeira troca todos estão em DEFAULT — verifica qual
        // o manifest declarou como enabled="true".
        aliases.entries.firstOrNull { (_, aliasName) ->
            pm.getComponentEnabledSetting(ComponentName(this, aliasName)) ==
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT &&
            pm.getActivityInfo(ComponentName(this, aliasName), 0).enabled
        }?.let { return it.key }

        return "default"
    }
}
