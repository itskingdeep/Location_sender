import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sendera/bloc/location_bloc.dart';
import 'package:sendera/bloc/location_event.dart';
import 'package:sendera/bloc/location_state.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  @override
  void initState() {
    super.initState();
    // ऐप शुरू होते ही automatically permission check करें
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationBloc>().add(CheckLocationPermission());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sender App"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            // Loading state
            if (state is LocationInitial) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Checking location permissions...'),
                ],
              );
            }

            // Permission denied state
            if (state is LocationPermissionDenied) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Location Permission Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please enable location permissions to share your location',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // App settings में open करें
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Open Settings'),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      context.read<LocationBloc>().add(CheckLocationPermission());
                    },
                    child: const Text('Retry Permission Check'),
                  ),
                ],
              );
            }

            // Permission granted but not sharing
            if (state is LocationPermissionGranted) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Permission Granted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You can now start sharing your location',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LocationBloc>().add(StartLocationSharing());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Start Sharing Location'),
                  ),
                ],
              );
            }

            // Sharing in progress
            if (state is LocationSharingInProgress) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.isSharing ? Icons.location_on : Icons.location_off,
                    size: 64,
                    color: state.isSharing ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.isSharing ? 'Sharing Location' : 'Sharing Stopped',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.isSharing
                        ? 'Your location is being shared in background'
                        : 'Location sharing is paused',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (state.isSharing) {
                        context.read<LocationBloc>().add(StopLocationSharing());
                      } else {
                        context.read<LocationBloc>().add(StartLocationSharing());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      state.isSharing ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: Text(state.isSharing ? "Stop Sharing" : "Start Sharing"),
                  ),
                  if (state.isSharing) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    const Text(
                      'Sharing in progress...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              );
            }

            // Error state
            if (state is LocationSharingError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Error Occurred',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LocationBloc>().add(CheckLocationPermission());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              );
            }

            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}