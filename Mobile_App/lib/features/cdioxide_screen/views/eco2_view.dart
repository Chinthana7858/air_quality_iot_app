import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';


class Eco2VisualizationScreen extends StatefulWidget {
  const Eco2VisualizationScreen({super.key});

  @override
  State<Eco2VisualizationScreen> createState() => _Eco2VisualizationScreenState();
}

class _Eco2VisualizationScreenState extends State<Eco2VisualizationScreen> {
  double currentEco2 = 400;
  final List<FlSpot> eco2History = [];
  int timeCounter = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        currentEco2 = 400 + Random().nextInt(1600).toDouble(); // Simulating sensor data
        eco2History.add(FlSpot(timeCounter.toDouble(), currentEco2));
        if (eco2History.length > 20) {
          eco2History.removeAt(0);
        }
        timeCounter++;
      });
    });
  }

  Color getEco2Color(double value) {
    if (value < 800) return Colors.green;
    if (value < 1200) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eCO2 Visualization (ENS160 Sensor)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Radial Gauge for Live eCO2 Levels
            SizedBox(
              height: 250,
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: 400,
                    maximum: 2000,
                    ranges: [
                      GaugeRange(startValue: 400, endValue: 800, color: Colors.green),
                      GaugeRange(startValue: 800, endValue: 1200, color: Colors.orange),
                      GaugeRange(startValue: 1200, endValue: 2000, color: Colors.red),
                    ],
                    pointers: [
                      NeedlePointer(value: currentEco2, enableAnimation: true, needleColor: getEco2Color(currentEco2))
                    ],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          '${currentEco2.toStringAsFixed(0)} ppm',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Line Chart for Historical Trend
            Expanded(
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: eco2History,
                      isCurved: true,
                      color: getEco2Color(currentEco2),
                      barWidth: 4,
                      belowBarData: BarAreaData(show: true, color: getEco2Color(currentEco2).withOpacity(0.3)),
                    ),
                  ],
                  borderData: FlBorderData(show: true),
                  minY: 400,
                  maxY: 2000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
