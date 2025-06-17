import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/trip_stop_card.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;
  final String tripHeadsign;

  const TripDetailsPage({
    super.key,
    required this.tripId,
    required this.tripHeadsign,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  List<TripStop> _tripStops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripStops();
  }

  Future<void> _loadTripStops() async {
    try {
      final stops = await DatabaseService.getTripStops(widget.tripId);
      setState(() {
        _tripStops = stops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tripHeadsign,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          Container(
            height: 4,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: _isLoading ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tripStops.isEmpty
                    ? const Center(
                        child: Text('No stops found for this trip'),
                      )
                    : ListView.builder(
                        itemCount: _tripStops.length,
                        itemBuilder: (context, index) {
                          return TripStopCard(
                            tripStop: _tripStops[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
