import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  MqttBrowserClient? _client;
  
  // بيانات وسيط EMQX Cloud الخاص بمشروعك
  final String broker = 'wss://v291f168.ala.eu-central-1.emqxsl.com/mqtt';
  final int port = 8084;
  final String alertTopic = 'aeromedic/emergency/alerts';

  // بيانات الدخول التي تم إنشاؤها في Authentication
  final String username = 'flutter_user';
  final String password = 'flutter_user';

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> statusMessage = ValueNotifier<String>('Disconnected');

  Future<void> connect() async {
    final clientId = 'aeromedic_hub_${DateTime.now().millisecondsSinceEpoch}';
    statusMessage.value = 'Connecting to EMQX Cloud...';

    final browserClient = MqttBrowserClient.withPort(broker, clientId, port);
    browserClient.websocketProtocols = ['mqtt'];
    browserClient.setProtocolV311();
    browserClient.keepAlivePeriod = 20;
    browserClient.autoReconnect = true;

    browserClient.onConnected = () {
      isConnected.value = true;
      statusMessage.value = 'Connected to Cloud ✅';
    };

    browserClient.onDisconnected = () {
      isConnected.value = false;
      statusMessage.value = 'Disconnected ❌';
    };

    _client = browserClient;

    try {
      await _client!.connect(username, password);
    } catch (e) {
      isConnected.value = false;
      statusMessage.value = 'Error: $e';
    }
  }

  bool sendEmergencyAlert({
    required int heartRate,
    required int spo2,
    required String alertReason,
  }) {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      return false;
    }

    final payload = {
      'alert': alertReason,
      'priority': 'CRITICAL',
      'vitals': {
        'heart_rate': heartRate,
        'spo2': spo2,
      },
      'drone_dispatch_required': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    
    _client!.publishMessage(alertTopic, MqttQos.atLeastOnce, builder.payload!);
    return true;
  }

  void disconnect() {
    _client?.disconnect();
  }
}