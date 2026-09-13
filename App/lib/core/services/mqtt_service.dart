import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  MqttBrowserClient? _client;
  
  // 1. اسم النطاق فقط بدون wss:// وبدون /mqtt
  final String broker = 'v291f168.ala.eu-central-1.emqxsl.com';
  final int port = 8084;
  final String alertTopic = 'aeromedic/emergency/alerts';

  // بيانات الدخول
  final String username = 'flutter_user';
  final String password = 'flutter_user';

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> statusMessage = ValueNotifier<String>('Disconnected');

  Future<void> connect() async {
    final clientId = 'aeromedic_hub_${DateTime.now().millisecondsSinceEpoch}';
    statusMessage.value = 'Connecting to EMQX Cloud...';

    // 2. استخدام withPort مع اسم النطاق الصافي
    final browserClient = MqttBrowserClient.withPort('wss://$broker/mqtt', clientId, port);
    
    // أو إذا كانت نسخة المكتبة تدعم التمرير المباشر:
    // final browserClient = MqttBrowserClient(broker, clientId, maxConnectionAttempts: 3);
    // browserClient.port = port;

    browserClient.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    browserClient.setProtocolV311();
    browserClient.keepAlivePeriod = 20;
    browserClient.autoReconnect = true;

    // تفعيل الـ Logging لرؤية رسائل الإرسال والاتصال في الـ Console
    browserClient.logging(on: true);

    browserClient.onConnected = () {
      isConnected.value = true;
      statusMessage.value = 'Connected to Cloud ✅';
      print('MQTT: Successfully Connected!');
    };

    browserClient.onDisconnected = () {
      isConnected.value = false;
      statusMessage.value = 'Disconnected ❌';
      print('MQTT: Disconnected');
    };

    _client = browserClient;

    try {
      await _client!.connect(username, password);
    } catch (e) {
      isConnected.value = false;
      statusMessage.value = 'Error: $e';
      print('MQTT Connect Error: $e');
    }
  }

  bool sendEmergencyAlert({
    required int heartRate,
    required int spo2,
    required String alertReason,
  }) {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('MQTT: Cannot send alert, client not connected.');
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
    print('MQTT: Emergency payload published to $alertTopic');
    return true;
  }

  void disconnect() {
    _client?.disconnect();
  }
}