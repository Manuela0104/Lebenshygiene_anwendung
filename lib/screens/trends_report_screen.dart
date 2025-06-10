import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class TrendsReportScreen extends StatefulWidget {
  const TrendsReportScreen({super.key});

  @override
  State<TrendsReportScreen> createState() => _TrendsReportScreenState();
}

class _TrendsReportScreenState extends State<TrendsReportScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'Woche';
  String _selectedMetric = 'Alle';
  bool _isLoading = true;
  Map<String, List<double>> _chartData = {};
  Map<String, dynamic> _statistics = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _periods = ['Tag', 'Woche', 'Monat'];
  final List<String> _metrics = ['Alle', 'Wasser', 'Schritte', 'Schlaf', 'Kalorien', 'Stimmung'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _loadChartData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final endDate = DateTime.now();
      final startDate = _getStartDate(endDate);
      
      // Load data from Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      Map<String, List<double>> data = {
        'Wasser': [],
        'Schritte': [],
        'Schlaf': [],
        'Kalorien': [],
        'Stimmung': [],
      };

      Map<String, double> totals = {
        'Wasser': 0,
        'Schritte': 0,
        'Schlaf': 0,
        'Kalorien': 0,
        'Stimmung': 0,
      };

      int dataPoints = 0;

      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        data['Wasser']!.add((docData['water'] ?? 0).toDouble());
        data['Schritte']!.add((docData['steps'] ?? 0).toDouble());
        data['Schlaf']!.add((docData['sleep'] ?? 0).toDouble());
        data['Kalorien']!.add((docData['kcal'] ?? 0).toDouble());
        
        // Load mood data separately
        final moodDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('moodEntries')
            .doc(doc.id)
            .get();
        
        final moodLevel = moodDoc.exists ? (moodDoc.data()?['level'] ?? 3.0).toDouble() : 3.0;
        data['Stimmung']!.add(moodLevel);
        
        // Calculate totals
        totals['Wasser'] = totals['Wasser']! + (docData['water'] ?? 0).toDouble();
        totals['Schritte'] = totals['Schritte']! + (docData['steps'] ?? 0).toDouble();
        totals['Schlaf'] = totals['Schlaf']! + (docData['sleep'] ?? 0).toDouble();
        totals['Kalorien'] = totals['Kalorien']! + (docData['kcal'] ?? 0).toDouble();
        totals['Stimmung'] = totals['Stimmung']! + moodLevel;
        dataPoints++;
      }

      // Calculate averages and statistics
      Map<String, dynamic> stats = {};
      totals.forEach((key, value) {
        stats[key] = {
          'average': dataPoints > 0 ? value / dataPoints : 0,
          'total': value,
          'trend': _calculateTrend(data[key]!),
          'best': data[key]!.isEmpty ? 0 : data[key]!.reduce(math.max),
          'worst': data[key]!.isEmpty ? 0 : data[key]!.reduce(math.min),
        };
      });

      setState(() {
        _chartData = data;
        _statistics = stats;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Daten: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  DateTime _getStartDate(DateTime endDate) {
    switch (_selectedPeriod) {
      case 'Tag':
        return endDate.subtract(const Duration(hours: 24));
      case 'Woche':
        return endDate.subtract(const Duration(days: 7));
      case 'Monat':
        return DateTime(endDate.year, endDate.month - 1, endDate.day);
      default:
        return endDate.subtract(const Duration(days: 7));
    }
  }

  String _calculateTrend(List<double> data) {
    if (data.length < 2) return 'Neutral';
    
    final firstHalf = data.take(data.length ~/ 2).toList();
    final secondHalf = data.skip(data.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final difference = secondAvg - firstAvg;
    
    if (difference > 0.1) return 'Steigend';
    if (difference < -0.1) return 'Fallend';
    return 'Stabil';
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Steigend':
        return const Color(0xFF43e97b);
      case 'Fallend':
        return const Color(0xFFfa709a);
      default:
        return const Color(0xFF4facfe);
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'Steigend':
        return Icons.trending_up;
      case 'Fallend':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Future<void> _exportData() async {
    // Simulate export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.file_download, color: Colors.white),
            SizedBox(width: 8),
            Text('Export-Funktion wird implementiert... 📊'),
          ],
        ),
        backgroundColor: Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        color: Color(0xFF667eea),
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 40 : 20),
                        child: Column(
                          children: [
                            _buildFilters(isTablet),
                            const SizedBox(height: 30),
                            _buildStatsOverview(isTablet),
                            const SizedBox(height: 30),
                            _buildChart(isTablet),
                            const SizedBox(height: 30),
                            _buildDetailedStats(isTablet),
                            const SizedBox(height: 30),
                            _buildRecommendations(isTablet),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Trends & Bericht',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Daten exportieren',
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zeitraum & Metriken',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zeitraum',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          dropdownColor: const Color(0xFF2d3748),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value!;
                            });
                            _loadChartData();
                          },
                          items: _periods.map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metrik',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMetric,
                          dropdownColor: const Color(0xFF2d3748),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {
                              _selectedMetric = value!;
                            });
                          },
                          items: _metrics.map((metric) {
                            return DropdownMenuItem(
                              value: metric,
                              child: Text(metric),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(bool isTablet) {
    if (_statistics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Übersicht - $_selectedPeriod',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.8 : 1.5,
            children: _statistics.entries.map((entry) {
              final metric = entry.key;
              final data = entry.value;
              final trend = data['trend'] ?? 'Neutral';
              
              return _buildStatCard(
                metric,
                data['average'].toStringAsFixed(1),
                trend,
                _getMetricIcon(metric),
                _getMetricColor(metric),
                isTablet,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 24 : 20),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrendIcon(trend),
                color: _getTrendColor(trend),
                size: isTablet ? 16 : 14,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: _getTrendColor(trend),
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isTablet) {
    if (_chartData.isEmpty || _selectedMetric == 'Alle') {
      return _buildMultiLineChart(isTablet);
    } else {
      return _buildSingleLineChart(isTablet);
    }
  }

  Widget _buildSingleLineChart(bool isTablet) {
    final data = _chartData[_selectedMetric] ?? [];
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: isTablet ? 300 : 250,
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedMetric Verlauf',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.length.toDouble() - 1,
                minY: 0,
                maxY: data.reduce(math.max) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        _getMetricColor(_selectedMetric),
                        _getMetricColor(_selectedMetric).withOpacity(0.7),
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: _getMetricColor(_selectedMetric),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getMetricColor(_selectedMetric).withOpacity(0.3),
                          _getMetricColor(_selectedMetric).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLineChart(bool isTablet) {
    return Container(
      height: isTablet ? 300 : 250,
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alle Metriken im Vergleich',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1,
                lineBarsData: _buildNormalizedLineBars(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(isTablet),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildNormalizedLineBars() {
    List<LineChartBarData> bars = [];
    
    _chartData.forEach((metric, data) {
      if (data.isEmpty) return;
      
      // Normalize data to 0-1 range for comparison
      final maxVal = data.reduce(math.max);
      final normalizedData = data.map((val) => maxVal > 0 ? val / maxVal : 0).toList();
      
      bars.add(
        LineChartBarData(
          spots: normalizedData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.toDouble());
          }).toList(),
          isCurved: true,
          color: _getMetricColor(metric),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      );
    });
    
    return bars;
  }

  Widget _buildChartLegend(bool isTablet) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _chartData.keys.map((metric) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getMetricColor(metric),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              metric,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailedStats(bool isTablet) {
    if (_statistics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detaillierte Statistiken',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          ..._statistics.entries.map((entry) {
            final metric = entry.key;
            final data = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMetricColor(metric).withOpacity(0.8),
                              _getMetricColor(metric).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getMetricIcon(metric),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        metric,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durchschnitt',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                            Text(
                              data['average'].toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bester Wert',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                            Text(
                              data['best'].toStringAsFixed(1),
                              style: TextStyle(
                                color: const Color(0xFF43e97b),
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trend',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  _getTrendIcon(data['trend']),
                                  color: _getTrendColor(data['trend']),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data['trend'],
                                  style: TextStyle(
                                    color: _getTrendColor(data['trend']),
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendations(bool isTablet) {
    final recommendations = _getRecommendations();
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF43e97b),
            Color(0xFF38d9a9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43e97b).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Intelligente Empfehlungen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          ...recommendations.map((recommendation) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getRecommendations() {
    List<String> recommendations = [];
    
    _statistics.forEach((metric, data) {
      final average = data['average'];
      final trend = data['trend'];
      
      switch (metric) {
        case 'Wasser':
          if (average < 1.5) {
            recommendations.add('Trinke mehr Wasser! Ziel: mindestens 2 Liter täglich');
          } else if (trend == 'Fallend') {
            recommendations.add('Deine Wasseraufnahme ist rückläufig. Setze dir Erinnerungen');
          }
          break;
        case 'Schritte':
          if (average < 8000) {
            recommendations.add('Versuche täglich 10.000 Schritte zu erreichen');
          } else if (trend == 'Steigend') {
            recommendations.add('Großartig! Du steigerst deine tägliche Aktivität');
          }
          break;
        case 'Schlaf':
          if (average < 7) {
            recommendations.add('Versuche 7-9 Stunden Schlaf pro Nacht zu bekommen');
          } else if (trend == 'Stabil') {
            recommendations.add('Perfekt! Du hältst einen stabilen Schlafrhythmus');
          }
          break;
        case 'Stimmung':
          if (average < 3) {
            recommendations.add('Plane bewusst Zeit für entspannende Aktivitäten ein');
          } else if (trend == 'Steigend') {
            recommendations.add('Deine Stimmung verbessert sich! Weiter so!');
          }
          break;
      }
    });
    
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Du machst großartige Fortschritte in allen Bereichen!',
        'Halte deine gesunden Gewohnheiten bei',
        'Denke daran, auch mal Pausen einzulegen',
      ]);
    }
    
    return recommendations.take(4).toList();
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'Wasser':
        return const Color(0xFF4facfe);
      case 'Schritte':
        return const Color(0xFF43e97b);
      case 'Schlaf':
        return const Color(0xFF667eea);
      case 'Kalorien':
        return const Color(0xFFfa709a);
      case 'Stimmung':
        return const Color(0xFFfee140);
      default:
        return const Color(0xFF764ba2);
    }
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'Wasser':
        return Icons.water_drop;
      case 'Schritte':
        return Icons.directions_walk;
      case 'Schlaf':
        return Icons.bedtime;
      case 'Kalorien':
        return Icons.local_fire_department;
      case 'Stimmung':
        return Icons.mood;
      default:
        return Icons.analytics;
    }
  }
}