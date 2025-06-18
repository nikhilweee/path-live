import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Incident> _alerts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedAlerts();
  }

  Future<void> _loadCachedAlerts() async {
    final cachedAlerts = await getCachedAlerts();
    setState(() => _alerts = cachedAlerts);
    await _refreshAlerts(forceRefresh: false);
  }

  Future<void> _refreshAlerts({bool forceRefresh = true}) async {
    if (!mounted) return;

    // Assume forceRefresh implies that refresh indicator is loading
    if (!forceRefresh) {
      setState(() => _isLoading = true);
    }

    final alerts = await ApiService.loadAlerts(forceRefresh: forceRefresh);

    if (!mounted) return;

    setState(() {
      if (alerts != null) {
        _alerts = alerts;
      }
      if (!forceRefresh) {
        _isLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        forceMaterialTransparency: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: Column(
          children: [
            SizedBox(
              height: 4,
              child: _isLoading ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: _alerts.isEmpty
                  ? const Center(child: Text('No alerts'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        return _AlertCard(alert: alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Incident alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alert.subject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  DateFormat('M/d H:mm').format(alert.modifiedDateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              alert.preMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
