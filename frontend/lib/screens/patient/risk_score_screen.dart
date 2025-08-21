import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_pad_app/models/sensor_data_model.dart'; // 프로젝트 이름으로 수정
import 'package:smart_pad_app/services/websocket_service.dart'; // 프로젝트 이름으로 수정

enum MetricType { risk, pressure, temperature, humidity }

class RiskScoreScreen extends StatefulWidget {
  const RiskScoreScreen({super.key});

  @override
  _RiskScoreScreenState createState() => _RiskScoreScreenState();
}

class _RiskScoreScreenState extends State<RiskScoreScreen> {
  final WebSocketService _webSocketService = WebSocketService();
  MetricType _selected = MetricType.risk; // Default to 'risk' score
  SensorData? _latestSensorData;

  // Original data grid (heatmap resolution)
  static const int cols = 16;
  static const int rows = 24;

  // Display ranges for normalization
  final Map<MetricType, RangeValues> _ranges = const {
    MetricType.risk: RangeValues(0, 100),
    MetricType.pressure: RangeValues(0, 120),
    MetricType.temperature: RangeValues(20, 40),
    MetricType.humidity: RangeValues(20, 90),
  };

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    // TODO: Fetch the patient ID from the authenticated user.
    // For now, using a hardcoded value '1' as a placeholder.
    int patientId = 1;

    _webSocketService.connect(patientId)?.listen((data) {
      if (!mounted) return;
      setState(() {
        _latestSensorData = data;
      });
    }, onError: (error) {
      print('WebSocket stream error: $error');
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  // Generates heatmap data based on the selected metric.
  List<List<double>> _getGridDataForSelectedMetric() {
    final List<List<double>> grid =
    List.generate(rows, (_) => List.filled(cols, 0.0));

    if (_latestSensorData == null) {
      return grid; // Return an empty grid if no data is available.
    }

    // Apply the single sensor data to the entire grid.
    switch (_selected) {
      case MetricType.pressure:
        final value = _latestSensorData!.pressure.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = value;
          }
        }
        break;
      case MetricType.temperature:
        final value = _latestSensorData!.temperature.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = value;
          }
        }
        break;
      case MetricType.humidity:
        final value = _latestSensorData!.humidity.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = value;
          }
        }
        break;
      case MetricType.risk:
      default:
      // Risk score will be implemented later. Return a dummy grid for now.
        return List.generate(rows, (y) => List.generate(cols, (x) => 0.0));
    }
    return grid;
  }

  @override
  Widget build(BuildContext context) {
    final grid = _getGridDataForSelectedMetric();
    final range = _ranges[_selected]!;
    final minV = range.start;
    final maxV = range.end;

    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 스마트패드 데이터'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMetricSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: _HeatmapWithOutline(
                rows: rows,
                cols: cols,
                data: grid,
                minValue: minV,
                maxValue: maxV,
                outlineAssetPath: 'assets/images/human_shape.png',
                latestSensorData: _latestSensorData,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(minV, maxV),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final labels = {
      MetricType.risk: '위험도점수',
      MetricType.pressure: '압력',
      MetricType.temperature: '온도',
      MetricType.humidity: '습도',
    };
    final items = MetricType.values;

    return ToggleButtons(
      isSelected: items.map((m) => m == _selected).toList(),
      onPressed: (index) {
        setState(() {
          _selected = items[index];
        });
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
      children: items
          .map((m) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(labels[m]!, style: const TextStyle(fontSize: 14)),
      ))
          .toList(),
    );
  }

  Widget _buildLegend(double minV, double maxV) {
    if (_selected == MetricType.risk) {
      return const SizedBox.shrink(); // Hide the legend for risk score.
    }
    const steps = 20;
    return Column(
      children: [
        Row(
          children: List.generate(steps, (i) {
            final t = i / (steps - 1);
            return Expanded(child: Container(height: 10, color: _colorMap(t)));
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minV.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
            Text(maxV.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// A widget that overlays a heatmap on a human shape asset.
class _HeatmapWithOutline extends StatelessWidget {
  final int rows;
  final int cols;
  final List<List<double>> data;
  final double minValue;
  final double maxValue;
  final String outlineAssetPath;
  final SensorData? latestSensorData;

  const _HeatmapWithOutline({
    required this.rows,
    required this.cols,
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.outlineAssetPath,
    this.latestSensorData,
  });

  // Downsamples the original 16x24 grid to a 5x10 grid using block averaging.
  List<List<double>> _downsample({
    required List<List<double>> src,
    required int srcRows,
    required int srcCols,
    required int dstRows,
    required int dstCols,
  }) {
    final List<List<double>> dst =
    List.generate(dstRows, (_) => List.filled(dstCols, 0.0));

    final blockH = srcRows / dstRows;
    final blockW = srcCols / dstCols;

    for (int ry = 0; ry < dstRows; ry++) {
      for (int rx = 0; rx < dstCols; rx++) {
        final y0 = (ry * blockH).floor();
        final y1 = min(((ry + 1) * blockH).ceil(), srcRows);
        final x0 = (rx * blockW).floor();
        final x1 = min(((rx + 1) * blockW).ceil(), srcCols);

        double sum = 0;
        int cnt = 0;
        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            sum += src[y][x];
            cnt++;
          }
        }
        dst[ry][rx] = cnt == 0 ? 0.0 : sum / cnt;
      }
    }
    return dst;
  }

  @override
  Widget build(BuildContext context) {
    // Convert to a 5x10 grid for display.
    final sampled = _downsample(
      src: data,
      srcRows: rows,
      srcCols: cols,
      dstRows: 10,
      dstCols: 5,
    );

    return AspectRatio(
      aspectRatio: 5 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DotGridOverlay(
            rows: 10,
            cols: 5,
            data: sampled,
            minValue: minValue,
            maxValue: maxValue,
            latestSensorData: latestSensorData,
          ),
          IgnorePointer(
            ignoring: true,
            child: Image.asset(
              outlineAssetPath,
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// A widget that displays a grid of 50 dots with sensor values.
class _DotGridOverlay extends StatelessWidget {
  final int rows;
  final int cols;
  final List<List<double>> data;
  final double minValue;
  final double maxValue;
  final SensorData? latestSensorData;

  const _DotGridOverlay({
    required this.rows,
    required this.cols,
    required this.data,
    required this.minValue,
    required this.maxValue,
    this.latestSensorData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final cellW = c.maxWidth / cols;
        final cellH = c.maxHeight / rows;
        final size = (cellW < cellH ? cellW : cellH) * 0.8;

        return Column(
          children: List.generate(rows, (y) {
            return Expanded(
              child: Row(
                children: List.generate(cols, (x) {
                  final v = data[y][x];
                  final t = (maxValue == minValue)
                      ? 0.0
                      : ((v - minValue) / (maxValue - minValue))
                      .clamp(0.0, 1.0);
                  final color = _colorMap(t);

                  // Show actual data only on the first dot (y=0, x=0).
                  final bool isFirstDot = y == 0 && x == 0;

                  return Expanded(
                    child: Center(
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isFirstDot && latestSensorData != null
                            ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'P:${latestSensorData!.pressure}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'T:${latestSensorData!.temperature}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'H:${latestSensorData!.humidity}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

// Color mapping: blue -> green -> yellow -> red
Color _colorMap(double t) {
  if (t <= 0.33) {
    final k = t / 0.33;
    return _lerpColor(const Color(0xFF1E3A8A), const Color(0xFF10B981), k);
  } else if (t <= 0.66) {
    final k = (t - 0.33) / 0.33;
    return _lerpColor(const Color(0xFF10B981), const Color(0xFFF59E0B), k);
  } else {
    final k = (t - 0.66) / 0.34;
    return _lerpColor(const Color(0xFFF59E0B), const Color(0xFFDC2626), k);
  }
}

Color _lerpColor(Color a, Color b, double t) {
  return Color.fromARGB(
    (a.alpha + (b.alpha - a.alpha) * t).round(),
    (a.red + (b.red - a.red) * t).round(),
    (a.green + (b.green - a.green) * t).round(),
    (a.blue + (b.blue - a.blue) * t).round(),
  );
}
