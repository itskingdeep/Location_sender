// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sendera/background_service.dart';
import 'package:sendera/bloc/location_event.dart';
import 'package:sendera/bloc/location_state.dart';
import 'package:sendera/main.dart';
import 'package:sendera/screen/LocationSenderScreen.dart';

import 'bloc/location_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => LocationBloc(service: FlutterBackgroundService()),
        child: const LocationSharingScreen(),
      ),
    );
  }
}

