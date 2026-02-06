import 'package:flutter/material.dart';
import '../../services/app_info_service.dart';
import '../../services/notification_service.dart';
import '../../storage/settings_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    NotificationService? notificationService,
    SettingsStorage? settingsStorage,
    AppInfoService? appInfoService,
  })  : _notificationService = notificationService,
        _settingsStorage = settingsStorage,
        _appInfoService = appInfoService;

  final NotificationService? _notificationService;
  final SettingsStorage? _settingsStorage;
  final AppInfoService? _appInfoService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final NotificationService _notificationService;
  late final SettingsStorage _settingsStorage;
  late final AppInfoService _appInfoService;

  bool _notificationsEnabled = false;
  int _notificationHour = 9;
  int _notificationMinute = 0;
  bool _notificationsSupported = true;
  String _versionBuild = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget._notificationService ?? NotificationServiceImpl();
    _settingsStorage = widget._settingsStorage ?? SettingsStorageImpl();
    _appInfoService = widget._appInfoService ?? AppInfoServiceImpl();
    _load();
  }

  Future<void> _load() async {
    await _notificationService.initialize();
    final enabled = await _settingsStorage.getNotificationsEnabled();
    final hour = await _settingsStorage.getNotificationHour();
    final minute = await _settingsStorage.getNotificationMinute();
    final supported = await _notificationService.isSupported;
    final versionBuild = await _appInfoService.getVersionAndBuild();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _notificationHour = hour;
        _notificationMinute = minute;
        _notificationsSupported = supported;
        _versionBuild = versionBuild;
        _loading = false;
      });
    }
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    await _settingsStorage.setNotificationsEnabled(value);
    if (value) {
      await _notificationService.requestPermission();
      await _notificationService.scheduleDailyAt(
          _notificationHour, _notificationMinute);
    } else {
      await _notificationService.cancelAll();
    }
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notificationHour, minute: _notificationMinute),
    );
    if (picked == null || !mounted) return;
    await _settingsStorage.setNotificationTime(picked.hour, picked.minute);
    if (_notificationsEnabled) {
      await _notificationService.scheduleDailyAt(picked.hour, picked.minute);
    }
    if (mounted) {
      setState(() {
        _notificationHour = picked.hour;
        _notificationMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Daily notifications'),
                  subtitle: Text(
                    _notificationsSupported
                        ? 'Remind you to check in each day'
                        : 'Not available on this device',
                  ),
                  value: _notificationsEnabled,
                  onChanged: _notificationsSupported ? _setNotificationsEnabled : null,
                ),
                if (_notificationsSupported && _notificationsEnabled) ...[
                  ListTile(
                    title: const Text('Reminder time'),
                    trailing: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(hour: _notificationHour, minute: _notificationMinute),
                      ),
                    ),
                    onTap: _pickTime,
                  ),
                ],
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    _versionBuild,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
