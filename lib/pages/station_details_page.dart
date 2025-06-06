import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StationDetailsPage extends StatefulWidget {
  final Station station;

  const StationDetailsPage({
    super.key,
    required this.station,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _updateDatabase();
  }

  Future<void> _updateDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final dbPath = await ApiService.updatePathDatabase();
      if (mounted) {
        setState(() {
          _statusMessage = dbPath != null 
              ? 'Database ready' 
              : 'Failed to update database';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to update database: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.consideredStationFullName),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 4,
            child: _isLoading ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: Center(
              child: _statusMessage != null
                  ? Text(
                      _statusMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'Updating database',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
