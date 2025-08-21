import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Wasserzähler-Bildschirm für die Überwachung der täglichen Wasseraufnahme
/// 
/// Bietet Funktionalitäten für:
/// - Tägliche Wasseraufnahme in Gläsern verfolgen
/// - Personalisierte Wasserziele basierend auf Benutzerprofil
/// - Visuelle Darstellung der Wasseraufnahme mit Glasmotiv
/// - Fortschrittsanzeige und Statistiken
/// - Integration mit dem täglichen Daten-Tracking
/// 
/// Der Bildschirm verwendet eine Glasmotiv-Metapher (250ml pro Glas)
/// und speichert alle Daten in Firestore.
class WaterCounterScreen extends StatefulWidget {
  const WaterCounterScreen({super.key});

  @override
  State<WaterCounterScreen> createState() => _WaterCounterScreenState();
}

/// State-Klasse für den Wasserzähler-Bildschirm
/// 
/// Verwaltet Wasseraufnahme-Daten, Ziele und Animationen.
/// Implementiert Firestore-Integration für Datenpersistierung,
/// Animationen für Fade, Scale und Ripple-Effekte.
/// Bietet eine intuitive Benutzeroberfläche mit visuellen
/// Wasserelementen und Fortschrittsanzeigen.
class _WaterCounterScreenState extends State<WaterCounterScreen> with TickerProviderStateMixin {
  int _glasses = 0;
  int _maxGlasses = 8;
  final double _glassVolume = 0.25; // 250ml
  double _waterGoal = 2.0;
  bool _loading = true;
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    
    _loadGoalAndWater();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalAndWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _waterGoal = (userDoc.data()?['zielWater'] ?? 2.0).toDouble();
          _maxGlasses = (_waterGoal / _glassVolume).round();
        });
      }
      
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final waterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .get();
      
      if (waterDoc.exists) {
        setState(() {
          _glasses = ((waterDoc.data()?['water'] ?? 0.0) / _glassVolume).round();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Daten: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => _loading = false);
      _animationController.forward();
    }
  }

  Future<void> _saveWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .set({'water': _glasses * _glassVolume}, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _addGlass() {
    if (_glasses < _maxGlasses) {
      setState(() {
        _glasses++;
      });
      _rippleController.forward().then((_) => _rippleController.reset());
      _saveWater();
      
      // Haptic feedback would be nice here
      if (_glasses == _maxGlasses) {
        _showCelebration();
      }
    }
  }

  void _removeGlass() {
    if (_glasses > 0) {
      setState(() {
        _glasses--;
      });
      _saveWater();
    }
  }

  void _showCelebration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 8),
            Text('Glückwunsch! Du hast dein Wasserziel erreicht! 🎉'),
          ],
        ),
        backgroundColor: const Color(0xFF4facfe),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        color: Color(0xFF4facfe),
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildWaterProgressCard(),
                            const SizedBox(height: 30),
                            _buildGlassesGrid(),
                            const SizedBox(height: 30),
                            _buildQuickActions(),
                            const SizedBox(height: 30),
                            _buildTips(),
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
              Color(0xFF4facfe),
              Color(0xFF00c2ff),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Wasserzähler',
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
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaterProgressCard() {
    final currentLiters = _glasses * _glassVolume;
    final progress = (currentLiters / _waterGoal).clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2d3748),
            const Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heutiges Ziel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00c2ff)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_waterGoal.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4facfe)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Icon(
                    isComplete ? Icons.water_drop : Icons.water_drop_outlined,
                    color: const Color(0xFF4facfe),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentLiters.toStringAsFixed(1)} L',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isComplete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ziel erreicht!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassesGrid() {
    return Container(
      padding: const EdgeInsets.all(25),
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
          const Text(
            'Wassergläser',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf ein Glas, um Wasser hinzuzufügen',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: _maxGlasses,
            itemBuilder: (context, index) {
              final isFilled = index < _glasses;
              return GestureDetector(
                onTap: () {
                  if (isFilled) {
                    _removeGlass();
                  } else {
                    _addGlass();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: isFilled
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF4facfe), Color(0xFF00c2ff)],
                          )
                        : null,
                    color: isFilled ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled
                          ? const Color(0xFF4facfe)
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4facfe).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                        color: isFilled ? Colors.white : Colors.white.withOpacity(0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_glassVolume.toStringAsFixed(1)}L',
                        style: TextStyle(
                          color: isFilled ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Glas hinzufügen',
            Icons.add,
            const Color(0xFF4facfe),
            _glasses < _maxGlasses ? _addGlass : null,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            'Glas entfernen',
            Icons.remove,
            const Color(0xFFfa709a),
            _glasses > 0 ? _removeGlass : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback? onTap) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                )
              : null,
          color: isEnabled ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.3),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF4facfe),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Hydratations-Tipps',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            'Trinke gleich nach dem Aufwachen ein Glas Wasser',
            'Führe eine Wasserflasche mit dir',
            'Stelle Erinnerungen auf deinem Handy ein',
            'Trinke vor jeder Mahlzeit ein Glas Wasser',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4facfe),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Wasserzähler Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Verfolge deine tägliche Wasseraufnahme und erreiche dein Hydratationsziel. Jedes Glas entspricht ${_glassVolume.toStringAsFixed(1)}L Wasser.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Verstanden',
              style: TextStyle(color: Color(0xFF4facfe), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 