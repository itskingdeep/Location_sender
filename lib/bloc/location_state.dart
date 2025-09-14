abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationPermissionGranted extends LocationState {}

class LocationPermissionDenied extends LocationState {}

class LocationSharingInProgress extends LocationState {
  final bool isSharing;

  LocationSharingInProgress({required this.isSharing});
}

class LocationSharingError extends LocationState {
  final String message;

  LocationSharingError({required this.message});
}