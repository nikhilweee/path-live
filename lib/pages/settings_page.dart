import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Map<String, int> _settings = {};
  bool _isLoading = true;

  // Settings configuration
  static const _settingsConfig = [
    {
      'key': 'progressBarDuration',
      'title': 'Auto-refresh',
      'subtitle': 'Refresh interval',
      'options': [15, 30, 60],
      'labels': ['15s', '30s', '60s'],
    },
    {
      'key': 'countdownThreshold',
      'title': 'Countdown timer',
      'subtitle': 'When to show countdown',
      'options': [0, 300, 900],
      'labels': ['Never', '5min', '15min'],
    },
    {
      'key': 'previousTrainsCount',
      'title': 'Previous trains',
      'subtitle': 'Past trains to show',
      'options': [0, 5, 15],
      'labels': ['None', '5', '15'],
    },
    {
      'key': 'futureTrainsCount',
      'title': 'Future trains',
      'subtitle': 'Upcoming trains to show',
      'options': [10, 25, 50],
      'labels': ['10', '25', '50'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final values = await Future.wait([
      getSetting(Setting.progressBarDuration),
      getSetting(Setting.countdownThreshold),
      getSetting(Setting.previousTrainsCount),
      getSetting(Setting.futureTrainsCount),
    ]);

    setState(() {
      _settings['progressBarDuration'] = values[0];
      _settings['countdownThreshold'] = values[1];
      _settings['previousTrainsCount'] = values[2];
      _settings['futureTrainsCount'] = values[3];
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, int value) async {
    await _saveSetting(key, value);
    setState(() {
      _settings[key] = value;
    });
  }

  Future<void> _saveSetting(String key, int value) async {
    switch (key) {
      case 'progressBarDuration':
        await setSetting(Setting.progressBarDuration, value);
      case 'previousTrainsCount':
        await setSetting(Setting.previousTrainsCount, value);
      case 'futureTrainsCount':
        await setSetting(Setting.futureTrainsCount, value);
      case 'countdownThreshold':
        await setSetting(Setting.countdownThreshold, value);
    }
  }

  Future<void> _resetSettings() async {
    await resetAllTrainSettings();
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSettings,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _settingsConfig.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final config = _settingsConfig[index];
                return _buildSettingSection(config);
              },
            ),
    );
  }

  Widget _buildSettingSection(Map<String, dynamic> config) {
    final key = config['key'] as String;
    final title = config['title'] as String;
    final subtitle = config['subtitle'] as String;
    final options = config['options'] as List<int>;
    final labels = config['labels'] as List<String>;
    final currentValue = _settings[key] ?? options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: options.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return ButtonSegment<int>(
                value: value,
                label: Text(labels[index]),
              );
            }).toList(),
            selected: {currentValue},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                _updateSetting(key, selection.first);
              }
            },
          ),
        ),
      ],
    );
  }
}
