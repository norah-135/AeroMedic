import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  MqttBrowserClient? _client;
  final String broker = 'ws://broker.emqx.io/mqtt';
  final int port = 8083;
  final String alertTopic = 'aeromedic/emergency/alerts';

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> statusMessage = ValueNotifier<String>('Disconnected');

  Future<void> connect() async {
    final clientId = 'aeromedic_hub_${DateTime.now().millisecondsSinceEpoch}';
    statusMessage.value = 'Connecting to EMQX...';

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
      await _client!.connect();
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
      'vitals': {'heart_rate': heartRate, 'spo2': spo2},
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