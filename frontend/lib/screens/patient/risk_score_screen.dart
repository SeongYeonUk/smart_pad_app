import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:smart_pad_app/models/sensor_data_model.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';

enum MetricType { risk, pressure, temperature, humidity }

// ===== 환경 설정 =====
const String kBaseUrl = "http://192.168.0.101:8080";
const String kWsPath = "/ws/sensor";
const int kLatestFetchLimit = 1;

class RiskScoreScreen extends StatefulWidget {
  const RiskScoreScreen({super.key});

  @override
  RiskScoreScreenState createState() => RiskScoreScreenState();
}

class RiskScoreScreenState extends State<RiskScoreScreen>
    with WidgetsBindingObserver {
  WebSocket? _ws;

  MetricType _selected = MetricType.risk;
  SensorData? _latestSensorData;
  String? _jwt;

  bool _loadingJwt = true;
  bool _loadingLatest = false;
  bool _wsConnected = false;

  Timer? _pollTimer;           // 1초 폴링
  String? _lastSignature;      // 중복 업데이트 방지

  static const int cols = 16;
  static const int rows = 24;

  final Map<MetricType, RangeValues> _ranges = const {
    MetricType.risk: RangeValues(0, 100),
    MetricType.pressure: RangeValues(0, 120),
    MetricType.temperature: RangeValues(20, 40),
    MetricType.humidity: RangeValues(20, 90),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _disconnectWebSocket();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_jwt == null) return;
    if (state == AppLifecycleState.resumed) {
      _connectWebSocket(jwt: _jwt!);
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
      _disconnectWebSocket();
    }
  }

  Future<void> _bootstrap() async {
    final token = context.read<AuthProvider>().token;
    setState(() {
      _jwt = token;
      _loadingJwt = false;
    });

    if (_jwt == null) return;

    _connectWebSocket(jwt: _jwt!);
    await _fetchLatestOnce();
    _startPolling(); // 앱 시작 후 1초 주기 갱신
  }

  /// 부모 AppBar의 새로고침 버튼에서 호출할 공개 메서드
  Future<void> fetchLatestOncePublic() => _fetchLatestOnce();

  // ---------- 1초 폴링 ----------
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchLatestOnce();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  // -----------------------------

  // 최신 1건만 반영 + 같은 레코드는 무시
  void _updateLatestFromDynamic(dynamic obj) {
    Map<String, dynamic>? m;
    if (obj is List && obj.isNotEmpty && obj.first is Map<String, dynamic>) {
      m = obj.first as Map<String, dynamic>;
    } else if (obj is Map<String, dynamic>) {
      m = obj;
    }
    if (m == null) return;

    final sig = '${m['id'] ?? ''}|${m['createdAt'] ?? m['timestamp'] ?? ''}|'
        '${m['pressure'] ?? ''}|${m['temperature'] ?? ''}|${m['humidity'] ?? ''}';

    if (_lastSignature == sig) return; // 중복이면 리빌드 생략
    _lastSignature = sig;

    final sd = SensorData.fromJson(m);
    if (!mounted) return;
    setState(() => _latestSensorData = sd);
  }

  Future<void> _fetchLatestOnce() async {
    final jwt = context.read<AuthProvider>().token;

    if (!mounted) return;
    setState(() => _loadingLatest = true);

    try {
      final uri = Uri.parse("$kBaseUrl/api/sensor-data/latest?limit=$kLatestFetchLimit");
      final headers = <String, String>{"Accept": "application/json"};
      if (jwt != null) headers["Authorization"] = "Bearer $jwt";

      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 401) {
        _showSnack("인증 만료. 다시 로그인 해주세요.");
        if (mounted) setState(() => _jwt = null);
        return;
      }
      if (res.statusCode >= 400) {
        _showSnack("최신 데이터 로드 실패 (${res.statusCode})");
        return;
      }

      _updateLatestFromDynamic(json.decode(res.body));
    } catch (e) {
      _showSnack("최신 데이터 로드 에러: $e");
    } finally {
      if (mounted) setState(() => _loadingLatest = false);
    }
  }

  // ----- WebSocket -----
  String _buildWsUrl(String httpBase, String path) {
    final uri = Uri.parse(httpBase);
    final isHttps = uri.scheme.toLowerCase() == 'https';
    final scheme = isHttps ? 'wss' : 'ws';
    final hostPort = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    final normPath = path.startsWith('/') ? path : '/$path';
    return '$scheme://$hostPort$normPath';
  }

  void _connectWebSocket({required String jwt}) async {
    _disconnectWebSocket();

    final wsUrl = _buildWsUrl(kBaseUrl, kWsPath);
    debugPrint('🔌 WS connect → $wsUrl');

    try {
      final ws = await WebSocket.connect(
        wsUrl,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Accept': 'application/json',
        },
      );

      _ws = ws;
      if (!mounted) return;
      setState(() => _wsConnected = true);

      ws.listen((message) {
        try {
          final dynamic obj = message is String ? jsonDecode(message) : message;
          _updateLatestFromDynamic(obj); // WS 수신도 공통 경로로
        } catch (e) {
          debugPrint('WS parse error: $e');
        }
      }, onError: (error) {
        debugPrint('WebSocket stream error: $error');
        if (!mounted) return;
        setState(() => _wsConnected = false);
        _showSnack("웹소켓 오류: $error");
      }, onDone: () {
        debugPrint('WebSocket closed (code=${ws.closeCode}, reason=${ws.closeReason})');
        if (!mounted) return;
        setState(() => _wsConnected = false);
      });
    } catch (e) {
      debugPrint('❌ WS connect error: $e');
      if (!mounted) return;
      setState(() => _wsConnected = false);
      _showSnack("웹소켓 연결 실패: $e");
    }
  }

  void _disconnectWebSocket() {
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;
    _wsConnected = false;
  }

  void _retryAll() {
    final token = context.read<AuthProvider>().token;
    _disconnectWebSocket();
    setState(() => _jwt = token);
    if (_jwt != null) {
      _connectWebSocket(jwt: _jwt!);
      _fetchLatestOnce();
      _startPolling();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  List<List<double>> _getGridDataForSelectedMetric() {
    final grid = List.generate(rows, (_) => List.filled(cols, 0.0));

    if (_latestSensorData == null) return grid;

    switch (_selected) {
      case MetricType.pressure:
        final v = _latestSensorData!.pressure.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = v;
          }
        }
        break;
      case MetricType.temperature:
        final v = _latestSensorData!.temperature.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = v;
          }
        }
        break;
      case MetricType.humidity:
        final v = _latestSensorData!.humidity.toDouble();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = v;
          }
        }
        break;
      case MetricType.risk:
      // 위험도 탭: t=0(딥블루) 고정값 → 기본 동그라미만 보이게
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            grid[r][c] = 0.0;
          }
        }
        break;
    }
    return grid;
  }

  @override
  Widget build(BuildContext context) {
    final range = _ranges[_selected]!;
    final minV = range.start;
    final maxV = range.end;

    // 🔴 내부 Scaffold/AppBar 제거 → 상위에서 AppBar를 제공
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildBody(minV, maxV),
    );
  }

  Widget _buildBody(double minV, double maxV) {
    if (_jwt == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '로그인이 필요합니다.\n앱에서 먼저 로그인 후 다시 시도하세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _retryAll,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final grid = _getGridDataForSelectedMetric();

    return Column(
      children: [
        _buildMetricSelector(),
        const SizedBox(height: 8),
        _SimpleStatusBar(wsConnected: _wsConnected, loadingLatest: _loadingLatest),
        const SizedBox(height: 12),
        Expanded(
          child: _latestSensorData == null
              ? const Center(child: Text('센서 데이터 수신 대기중...'))
              : _HeatmapWithOutline(
            rows: rows,
            cols: cols,
            data: grid,
            minValue: minV,
            maxValue: maxV,
            outlineAssetPath: 'assets/images/human_shape.png',
            latestSensorData: _latestSensorData,
            selected: _selected,
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(minV, maxV),
      ],
    );
  }

  Widget _buildMetricSelector() {
    final labels = {
      MetricType.risk: '위험도',
      MetricType.pressure: '압력',
      MetricType.temperature: '온도',
      MetricType.humidity: '습도',
    };
    final items = MetricType.values;

    return ToggleButtons(
      isSelected: items.map((m) => m == _selected).toList(),
      onPressed: (i) => setState(() => _selected = items[i]),
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
    if (_selected == MetricType.risk) return const SizedBox.shrink();
    const steps = 20;
    return Column(
      children: [
        Row(
          children: List.generate(
            steps,
                (i) => Expanded(
              child: Container(height: 10, color: _colorMap(i / (steps - 1))),
            ),
          ),
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

class _SimpleStatusBar extends StatelessWidget {
  final bool wsConnected;
  final bool loadingLatest;

  const _SimpleStatusBar({
    required this.wsConnected,
    required this.loadingLatest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          wsConnected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: wsConnected ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(wsConnected ? '실시간 연결됨' : '실시간 끊김',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 12),
        if (loadingLatest)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _HeatmapWithOutline extends StatelessWidget {
  final int rows;
  final int cols;
  final List<List<double>> data;
  final double minValue;
  final double maxValue;
  final String outlineAssetPath;
  final SensorData? latestSensorData;
  final MetricType selected;

  const _HeatmapWithOutline({
    required this.rows,
    required this.cols,
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.outlineAssetPath,
    required this.latestSensorData,
    required this.selected,
  });

  List<List<double>> _downsample({
    required List<List<double>> src,
    required int srcRows,
    required int srcCols,
    required int dstRows,
    required int dstCols,
  }) {
    final dst = List.generate(dstRows, (_) => List.filled(dstCols, 0.0));
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
            selected: selected,
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

class _DotGridOverlay extends StatelessWidget {
  final int rows;
  final int cols;
  final List<List<double>> data;
  final double minValue;
  final double maxValue;
  final SensorData? latestSensorData;
  final MetricType selected;

  const _DotGridOverlay({
    required this.rows,
    required this.cols,
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.latestSensorData,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final cellW = c.maxWidth / cols;
        final cellH = c.maxHeight / rows;
        final size = (cellW < cellH ? cellW : cellH) * 0.8;

        String? _labelFor(SensorData d) {
          switch (selected) {
            case MetricType.pressure:
              return 'P:${d.pressure}';
            case MetricType.temperature:
              return 'T:${d.temperature}';
            case MetricType.humidity:
              return 'H:${d.humidity}';
            case MetricType.risk:
              return null; // 위험도 탭은 라벨 없음
          }
        }

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

                  final isFirstDot = y == 0 && x == 0;

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
                        child: (isFirstDot && latestSensorData != null)
                            ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _labelFor(latestSensorData!) ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
