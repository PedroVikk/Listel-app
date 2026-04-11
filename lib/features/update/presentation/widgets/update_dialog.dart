import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/app_update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> showIfNeeded(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(Icons.system_update_outlined, color: colorScheme.primary, size: 32),
      title: Text('Nova versão disponível'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versão ${info.version}',
            style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          ),
          if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              info.releaseNotes!,
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Agora não'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final uri = Uri.parse(info.downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Baixar'),
        ),
      ],
    );
  }
}
