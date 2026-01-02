import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../services/app_settings.dart';
import '../services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final s = controller.settings;

        if (!controller.loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _sectionTitle(context, 'Customization'),
            const SizedBox(height: 12),
            _colorTile(
              context: context,
              title: 'Border color',
              color: s.borderColor,
              onPick: (c) => controller.update(s.copyWith(borderColor: c)),
            ),
            _colorTile(
              context: context,
              title: 'Label color',
              color: s.labelColor,
              onPick: (c) => controller.update(s.copyWith(labelColor: c)),
            ),
            _colorTile(
              context: context,
              title: 'Background color',
              color: s.backgroundColor,
              onPick: (c) => controller.update(s.copyWith(backgroundColor: c)),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font size',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: s.fontScale,
                      min: 0.85,
                      max: 1.35,
                      divisions: 10,
                      label: s.fontScale.toStringAsFixed(2),
                      onChanged: (v) =>
                          controller.update(s.copyWith(fontScale: v)),
                    ),
                    Text('Current: ${s.fontScale.toStringAsFixed(2)}x'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Results Format'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show figure section'),
              value: s.showFigureSection,
              onChanged: (v) =>
                  controller.update(s.copyWith(showFigureSection: v)),
            ),
            const SizedBox(height: 12),
            _rangeCard(
              context: context,
              title: 'Jodi range (inclusive)',
              start: s.jodiStart,
              end: s.jodiEnd,
              onChanged: (start, end) =>
                  controller.update(s.copyWith(jodiStart: start, jodiEnd: end)),
            ),
            const SizedBox(height: 12),
            _rangeCard(
              context: context,
              title: 'Figure range (inclusive)',
              start: s.figureStart,
              end: s.figureEnd,
              enabled: s.showFigureSection,
              onChanged: (start, end) => controller.update(
                s.copyWith(figureStart: start, figureEnd: end),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text('Reset settings to default'),
                trailing: const Icon(Icons.restore),
                onTap: () => controller.update(AppSettings.defaults),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  static Widget _colorTile({
    required BuildContext context,
    required String title,
    required Color color,
    required ValueChanged<Color> onPick,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
          ),
        ),
        onTap: () async {
          Color temp = color;
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: (c) => temp = c,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
          if (ok == true) {
            onPick(temp);
          }
        },
      ),
    );
  }

  static Widget _rangeCard({
    required BuildContext context,
    required String title,
    required int start,
    required int end,
    required void Function(int start, int end) onChanged,
    bool enabled = true,
  }) {
    final startCtrl = TextEditingController(text: start.toString());
    final endCtrl = TextEditingController(text: end.toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!enabled)
                  const Text(
                    'Disabled',
                    style: TextStyle(color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'End'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: !enabled
                    ? null
                    : () {
                        final s = int.tryParse(startCtrl.text.trim());
                        final e = int.tryParse(endCtrl.text.trim());
                        if (s == null || e == null) return;
                        if (s > e) return;
                        onChanged(s, e);
                      },
                child: const Text('Save Range'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
