import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StandaloneMqttTester(),
  ));
}

class StandaloneMqttTester extends StatefulWidget {
  const StandaloneMqttTester({super.key});

  @override
  State<StandaloneMqttTester> createState() => _StandaloneMqttTesterState();
}

class _StandaloneMqttTesterState extends State<StandaloneMqttTester> {
  MqttBrowserClient? _client;
  bool _isConnected = false;
  String _status = 'Initializing...';
  final String _topic = 'aeromedic/emergency/alerts';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final clientId = 'aeromedic_web_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _status = 'Connecting to broker.emqx.io:8083...');

    // الرابط الكامل المعتمد لمتصفح الويب
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
      print('✅ [TEST APP] MQTT Connected Successfully');
      setState(() {
        _isConnected = true;
        _status = 'Connected to EMQX Broker ✅';
      });
    };

    browserClient.onDisconnected = () {
      print('⚠️ [TEST APP] MQTT Disconnected');
      setState(() {
        _isConnected = false;
        _status = 'Disconnected ❌';
      });
    };

    _client = browserClient;

    try {
      await _client!.connect();
    } catch (e) {
      print('❌ [TEST APP] Exception: $e');
      setState(() {
        _isConnected = false;
        _status = 'Failed: $e';
      });
    }
  }

  void _sendAlert() {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MQTT not connected!'), backgroundColor: Colors.red),
      );
      return;
    }

    final payload = jsonEncode({
      'alert': 'SOS_TEST_ISOLATED',
      'heart_rate': 85,
      'spo2': 98,
      'sender': 'Standalone Flutter Web Tester',
      'timestamp': DateTime.now().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(_topic, MqttQos.atLeastOnce, builder.payload!);
    print('📤 [TEST APP SENT]: $payload');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 SOS Alert Sent to MQTTX!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AeroMedic MQTT Isolation Test'),
        backgroundColor: _isConnected ? Colors.teal : Colors.grey.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ),
            const SizedBox(height: 35),
            ElevatedButton.icon(
              onPressed: _isConnected ? _sendAlert : null,
              icon: const Icon(Icons.warning, color: Colors.white),
              label: const Text(
                'SEND TEST SOS',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected ? Colors.red : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isConnected)
              TextButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }
}