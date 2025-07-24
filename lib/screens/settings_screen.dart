import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = 0.5;
  bool _isMuted = false;
  late bool _currentDarkMode;

  @override
  void initState() {
    super.initState();
    _currentDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _currentDarkMode,
              onChanged: (value) {
                setState(() {
                  _currentDarkMode = value;
                });
                widget.onThemeToggle(value);
              },
              activeColor: Colors.green,
              secondary: const Icon(Icons.dark_mode),
            ),
            const Divider(height: 32),

            SwitchListTile(
              title: const Text('Mute Sounds'),
              value: _isMuted,
              onChanged: (value) {
                setState(() {
                  _isMuted = value;
                  if (_isMuted) _volume = 0.0;
                });
              },
              activeColor: Colors.redAccent,
              secondary: const Icon(Icons.volume_off),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.volume_up),
                const SizedBox(width: 12),
                Text('Volume', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${(_volume * 100).round()}%'),
              ],
            ),
            Slider(
              value: _volume,
              onChanged: _isMuted
                  ? null
                  : (value) {
                      setState(() {
                        _volume = value;
                      });
                    },
              min: 0.0,
              max: 1.0,
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
