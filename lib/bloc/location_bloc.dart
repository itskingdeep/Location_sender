// lib/bloc/location_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final FlutterBackgroundService service;
  StreamSubscription? _serviceSubscription;
  bool _isSharing = false;

  LocationBloc({required this.service}) : super(LocationInitial()) {
    on<StartLocationSharing>(_onStartLocationSharing);
    on<StopLocationSharing>(_onStopLocationSharing);
    on<CheckLocationPermission>(_onCheckLocationPermission);
    on<UpdateServiceState>(_onUpdateServiceState);
    add(CheckLocationPermission());

    // Listen to service state changes
    _listenToServiceState();
  }

  void _listenToServiceState() {
    _serviceSubscription = service.on('serviceState').listen((event) {
      if (event is Map<String, dynamic>) {
        final isRunning = event['isRunning'] as bool? ?? false;
        add(UpdateServiceState(isRunning: isRunning));
      }
    });
  }

  Future<void> _onStartLocationSharing(
      StartLocationSharing event,
      Emitter<LocationState> emit,
      ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(LocationSharingError(message: 'Location services are disabled'));
        return;
      }
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied());
        return;
      }

      // Start the service
      await service.startService();

      // Update state to indicate sharing is in progress
      emit(LocationSharingInProgress(isSharing: true));
    } catch (e) {
      emit(LocationSharingError(message: 'Failed to start service: $e'));
    }
  }

  Future<void> _onStopLocationSharing(
      StopLocationSharing event,
      Emitter<LocationState> emit,
      ) async {
    try {
      // Stop the service
      service.invoke('stopService', {'action': 'stop'});

      // Update state to indicate sharing has stopped
      emit(LocationSharingInProgress(isSharing: false));
    } catch (e) {
      emit(LocationSharingError(message: 'Failed to stop service: $e'));
    }
  }

  Future<void> _onCheckLocationPermission(
      CheckLocationPermission event,
      Emitter<LocationState> emit,
      ) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission if denied
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied());
      } else {
        emit(LocationPermissionGranted());
        if (!_isSharing) {
          add(StartLocationSharing());
        }
      }
    } catch (e) {
      emit(LocationSharingError(message: 'Permission check failed: $e'));
    }
  }

  void _onUpdateServiceState(
      UpdateServiceState event,
      Emitter<LocationState> emit,
      ) {
    _isSharing = event.isRunning;
    emit(LocationSharingInProgress(isSharing: _isSharing));
  }

  @override
  Future<void> close() {
    _serviceSubscription?.cancel();
    return super.close();
  }
}