import 'dart:async';
import 'package:flutter/foundation.dart';

class BleVitalData {
  final int heartRate;
  final int spo2;
  final bool isEmergencyTriggered;

  BleVitalData({
    required this.heartRate,
    required this.spo2,
    this.isEmergencyTriggered = false,
  });
}

class BleService {
  final _vitalStreamController = StreamController<BleVitalData>.broadcast();
  Stream<BleVitalData> get vitalStream => _vitalStreamController.stream;

  // فك تشفير مصفوفة البايتات القادمة من إشارة السوار
  void parseRawPayload(List<int> rawBytes) {
    if (rawBytes.length >= 3) {
      final heartRate = rawBytes[0];
      final spo2 = rawBytes[1];
      final statusFlag = rawBytes[2]; // 0 = Normal, 1 = IMU Fall/Critical

      _vitalStreamController.add(
        BleVitalData(
          heartRate: heartRate,
          spo2: spo2,
          isEmergencyTriggered: statusFlag == 1,
        ),
      );
    }
  }

  void dispose() {
    _vitalStreamController.close();
  }
}