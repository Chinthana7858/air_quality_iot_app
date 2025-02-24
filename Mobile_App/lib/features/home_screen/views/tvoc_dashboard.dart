import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TVOCDashboard extends StatefulWidget {
  @override
  _TVOCDashboardState createState() => _TVOCDashboardState();
}

class _TVOCDashboardState extends State<TVOCDashboard> {
  late MqttServerClient client;
  double currentTVOC = 50; // Default TVOC value
  List<FlSpot> tvocData = [];
  int time = 0;
  bool isConnected = false;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? mqttSubscription;

  @override
  void initState() {
    super.initState();
    _connectMQTT();
  }

  Future<void> _connectMQTT() async {
    client =
        MqttServerClient('c197f092.ala.us-east-1.emqxsl.com', 'flutter_client');
    client.port = 8883; // Use 1883 for TCP, 8883 for SSL/TLS
    client.secure = true;
    client.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs('krishantha', 'krishantha')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      setState(() {
        isConnected = true;
      });

      print('✅ MQTT Connected!');

      const tvocTopic = 'air_quality/tvoc';
      client.subscribe(tvocTopic, MqttQos.atLeastOnce);

      mqttSubscription?.cancel(); // Cancel previous listeners if any
      mqttSubscription = client.updates!
          .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var message in messages) {
          final recMsg = message.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(recMsg.payload.message);
          print("📩 TVOC Data Received: $payload ppb");
          _updateTVOC(payload);
        }
      });
    } catch (e) {
      print('❌ MQTT connection failed: $e');
    }
  }

  void _updateTVOC(String payload) {
    final tvocValue = double.tryParse(payload) ?? 50;
    setState(() {
      currentTVOC = tvocValue;
      tvocData.add(FlSpot(time.toDouble(), currentTVOC));

      if (tvocData.length > 20) {
        tvocData.removeAt(0); // Keep only the last 20 readings
      }
      time++;
    });
  }

  Color getTVOCColor() {
    if (currentTVOC < 150) return Colors.green;
    if (currentTVOC < 300) return Colors.yellow;
    return Colors.red;
  }

  String getTVOCStatus() {
    if (currentTVOC < 150) return "Good";
    if (currentTVOC < 300) return "Moderate";
    return "Unhealthy";
  }

  @override
  void dispose() {
    mqttSubscription?.cancel();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TVOC Visualization")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: getTVOCColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text("Current TVOC",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  Text("${currentTVOC.toStringAsFixed(1)} ppb",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(getTVOCStatus(),
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 500,
                    ranges: [
                      GaugeRange(
                          startValue: 0, endValue: 150, color: Colors.green),
                      GaugeRange(
                          startValue: 150, endValue: 300, color: Colors.yellow),
                      GaugeRange(
                          startValue: 300, endValue: 500, color: Colors.red),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(value: currentTVOC),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '$currentTVOC ppb',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: tvocData.isNotEmpty ? tvocData.first.x : 0,
                  maxX: tvocData.isNotEmpty ? tvocData.last.x : 10,
                  minY: 0,
                  maxY: 500,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30)),
                    bottomTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40)),
                  ),
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: Colors.black)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: tvocData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
