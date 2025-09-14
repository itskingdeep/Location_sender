abstract class LocationEvent {}

class StartLocationSharing extends LocationEvent {}

class StopLocationSharing extends LocationEvent {}

class CheckLocationPermission extends LocationEvent {}
class UpdateServiceState extends LocationEvent {
  final bool isRunning;
  UpdateServiceState({required this.isRunning});
}