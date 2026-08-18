import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/services/mvp1_ble_service.dart';
import 'package:app/core/services/mvp1_mqtt_service.dart';
import 'dart:async';
import 'dart:convert';

final GetIt sl = GetIt.instance;

class Mvp1DashboardScreen extends StatefulWidget {
  const Mvp1DashboardScreen({super.key});

  @override
  State<Mvp1DashboardScreen> createState() => _Mvp1DashboardScreenState();
}

class _Mvp1DashboardScreenState extends State<Mvp1DashboardScreen> {
  late final Mvp1BleService _bleService;
  late final Mvp1MqttService _mqttService;
  StreamSubscription<bool>? _mqttConnectionSubscription;

  double _heartRate = 78.0; // Mock heart rate
  double _spo2 = 98.0; // Mock SpO2
  bool _isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    _bleService = sl<Mvp1BleService>();
    _mqttService = sl<Mvp1MqttService>();
    _initializeServices();
    _subscribeToMqttConnection();
  }

  Future<void> _initializeServices() async {
    // BLE scanning disabled (no-op in service)
    // Connect to MQTT broker
    await _mqttService.connect();
  }

  void _subscribeToMqttConnection() {
    _mqttConnectionSubscription = _mqttService.connectionStateStream.listen(
      (isConnected) {
        if (mounted) {
          setState(() {
            _isMqttConnected = isConnected;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bleService.dispose();
    _mqttService.dispose();
    _mqttConnectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection status indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bluetooth status
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: _bleService.isDeviceConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BLE: ${_bleService.isDeviceConnected ? 'Connected' : 'Disconnected'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  // MQTT status
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: _isMqttConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MQTT: ${_isMqttConnected ? 'Connected' : 'Disconnected'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Heart Rate Card
              Expanded(
                child: Card(
                  color: Colors.grey[900],
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_heartRate.toInt()}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'bpm',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // SpO2 Card
              Expanded(
                child: Card(
                  color: Colors.grey[900],
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.opacity,
                          color: Colors.blue,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_spo2.toInt()}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'SpO2',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // SOS Button
              ElevatedButton.icon(
                onPressed: _sendEmergencyAlert, // Always enabled
                icon: const Icon(Icons.error_outline, color: Colors.white),
                label: const Text(
                  'SOS EMERGENCY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    // Print SOS triggered message
    print('🚨 [SOS TRIGGERED] Button clicked, sending payload...');

    // Prepare mock vitals as per instruction: Heart Rate: 78, SpO2: 98
    final String deviceId = 'aeromedic_device_001'; // In a real app, get from device info
    final DateTime timestamp = DateTime.now();
    final double spo2 = 98.0;
    final double hr = 78.0;

    final bool result = await _mqttService.publishEmergencyAlert(
      deviceId: deviceId,
      timestamp: timestamp,
      spo2: spo2,
      hr: hr,
    );

    if (result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency Alert Sent!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ MQTT Disconnected - Alert Failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}