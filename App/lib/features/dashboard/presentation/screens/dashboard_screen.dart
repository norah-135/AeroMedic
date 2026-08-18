import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app/core/services/mqtt_service.dart';
import 'package:app/core/services/ble_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MqttService _mqttService = MqttService();
  final BleService _bleService = BleService();

  int _heartRate = 78;
  int _spo2 = 98;
  Timer? _mockTimer;
  StreamSubscription<BleVitalData>? _vitalSubscription;

  @override
  void initState() {
    super.initState();
    _mqttService.connect();

    // الاستماع لبيانات السوار
    _vitalSubscription = _bleService.vitalStream.listen((data) {
      setState(() {
        _heartRate = data.heartRate;
        _spo2 = data.spo2;
      });

      if (data.isEmergencyTriggered) {
        _triggerSos(reason: 'AUTOMATIC_FALL_OR_HYPOXIA');
      }
    });

    // محاكاة مؤقتة للبيانات الحيوية أثناء مرحلة التطوير
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _bleService.parseRawPayload([
        75 + Random().nextInt(15),
        96 + Random().nextInt(4),
        0,
      ]);
    });
  }

  void _triggerSos({String reason = 'MANUAL_SOS_BUTTON'}) {
    final success = _mqttService.sendEmergencyAlert(
      heartRate: _heartRate,
      spo2: _spo2,
      alertReason: reason,
    );

    if (success) {
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
    } else {
      _mqttService.connect();
    }
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
            onPressed: () => _mqttService.connect(),
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
                ValueListenableBuilder<bool>(
                  valueListenable: _mqttService.isConnected,
                  builder: (context, connected, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: _mqttService.statusMessage,
                      builder: (context, msg, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: connected ? const Color(0xFF064E3B) : const Color(0xFF450A0A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                connected ? Icons.cloud_done : Icons.cloud_off,
                                color: connected ? const Color(0xFF34D399) : const Color(0xFFF87171),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: connected ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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
                ValueListenableBuilder<bool>(
                  valueListenable: _mqttService.isConnected,
                  builder: (context, connected, _) {
                    return Center(
                      child: InkWell(
                        onTap: connected ? () => _triggerSos() : null,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: connected
                                  ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                                  : [Colors.grey.shade700, Colors.grey.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: connected
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
                    );
                  },
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
    _mockTimer?.cancel();
    _vitalSubscription?.cancel();
    _bleService.dispose();
    _mqttService.disconnect();
    super.dispose();
  }
}