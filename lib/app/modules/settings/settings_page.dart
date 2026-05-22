import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/translations/app_translations.dart';
import 'settings_controller.dart';
import '../home/home_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    // No-op; values come from SettingsController
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language card
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_outlined),
                      const SizedBox(width: 8),
                      Text('language'.tr, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final selected = _controller.locale.value;
                    return Column(
                      children: [
                        RadioListTile<Locale>(
                          value: AppTranslations.en,
                          groupValue: selected,
                          onChanged: (v) async {
                            if (v != null) await _controller.setLocale(v);
                          },
                          title: Text('english'.tr),
                        ),
                        RadioListTile<Locale>(
                          value: AppTranslations.km,
                          groupValue: selected,
                          onChanged: (v) async {
                            if (v != null) await _controller.setLocale(v);
                          },
                          title: Text('khmer'.tr),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Theme card
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.color_lens_outlined),
                      const SizedBox(width: 8),
                      Text('theme'.tr, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final selected = _controller.themeMode.value;
                    return Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          groupValue: selected,
                          onChanged: (v) async {
                            if (v != null) await _controller.setThemeMode(v);
                          },
                          title: Text('system'.tr),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: selected,
                          onChanged: (v) async {
                            if (v != null) await _controller.setThemeMode(v);
                          },
                          title: Text('light'.tr),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: selected,
                          onChanged: (v) async {
                            if (v != null) await _controller.setThemeMode(v);
                          },
                          title: Text('dark'.tr),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Clear data card
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text('clear_data'.tr),
              subtitle: Text('clear_all_desc'.tr),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('clear_all_q'.tr),
                      content: Text('clear_all_desc'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('cancel'.tr),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('clear'.tr),
                        ),
                      ],
                    );
                  },
                );

                if (ok == true) {
                  await Get.find<HomeController>().clearAll();
                  Get.snackbar('saved'.tr, 'data_cleared'.tr, snackPosition: SnackPosition.BOTTOM);
                }
              },
            ),
          ),
         
        ],
      ),
    );
  }
}
