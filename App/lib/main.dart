import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(const AeroMedicApp());
}

class AeroMedicApp extends StatelessWidget {
  const AeroMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroMedic Dispatch Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF10B981),
          error: Color(0xFFEF4444),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MqttBrowserClient? _client;
  bool _isConnected = false;
  String _statusText = 'جاري الاتصال بالخادم...';

  // Topic & Telemetry
  final String _alertTopic = 'aeromedic/emergency/alerts';
  int _heartRate = 78;
  int _spo2 = 98;
  Timer? _telemetryTimer;

  @override
  void initState() {
    super.initState();
    _connectMqtt();
    _startTelemetrySimulation();
  }

  void _startTelemetrySimulation() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _heartRate = 75 + Random().nextInt(15);
          _spo2 = 96 + Random().nextInt(4);
        });
      }
    });
  }

  Future<void> _connectMqtt() async {
    final clientId = 'aeromedic_hub_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _statusText = 'Connecting to broker.emqx.io:8083...');

    final browserClient = MqttBrowserClient.withPort(
      'ws://broker.emqx.io/mqtt',
      clientId,
      8083,
    );

    browserClient.websocketProtocols = ['mqtt'];
    browserClient.setProtocolV311();
    browserClient.keepAlivePeriod = 20;
    browserClient.autoReconnect = true;

    browserClient.onConnected = () {
      setState(() {
        _isConnected = true;
        _statusText = 'Connected to Cloud ✅';
      });
    };

    browserClient.onDisconnected = () {
      setState(() {
        _isConnected = false;
        _statusText = 'Disconnected ❌';
      });
    };

    _client = browserClient;

    try {
      await _client!.connect();
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusText = 'Connection Error: $e';
      });
    }
  }

  void _sendSosAlert() {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MQTT is disconnected! Reconnecting...'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _connectMqtt();
      return;
    }

    final payload = {
      'alert': 'CRITICAL_MEDICAL_EMERGENCY',
      'priority': 'HIGH',
      'vitals': {'heart_rate': _heartRate, 'spo2': _spo2},
      'drone_dispatch_required': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final payloadString = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(payloadString);

    _client!.publishMessage(_alertTopic, MqttQos.atLeastOnce, builder.payload!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              '🚨 Emergency SOS Dispatched to Cloud!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.medical_services_rounded, color: Color(0xFF0EA5E9)),
            SizedBox(width: 10),
            Text('AeroMedic Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _connectMqtt,
            tooltip: 'إعادة الاتصال',
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كرت حالة الاتصال
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF064E3B) : const Color(0xFF450A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: _isConnected ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isConnected ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // العلامات الحيوية
                const Text(
                  '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Heart Rate',
                        subtitle: 'نبض القلب',
                        value: '$_heartRate',
                        unit: 'BPM',
                        icon: Icons.favorite,
                        accentColor: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'SpO2',
                        subtitle: 'نسبة الأكسجين',
                        value: '$_spo2',
                        unit: '%',
                        icon: Icons.water_drop,
                        accentColor: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // زر الـ SOS
                Center(
                  child: InkWell(
                    onTap: _isConnected ? _sendSosAlert : null,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isConnected
                              ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                              : [Colors.grey.shade700, Colors.grey.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: _isConnected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.4),
                                  blurRadius: 25,
                                  spreadRadius: 8,
                                )
                              ]
                            : [],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 55, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'إرسال استغاثة\nSOS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'عند الضغط يتم إرسال إشارة الطوارئ والبيانات الحيوية فوراً عبر MQTT',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Icon(icon, color: accentColor, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }
}