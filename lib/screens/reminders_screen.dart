import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    
    _loadReminders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .orderBy('time')
            .get();
        
        setState(() {
          _reminders = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'title': doc['title'] ?? '',
                    'time': (doc['time'] as Timestamp).toDate(),
                    'isActive': doc['isActive'] ?? true,
                  })
              .toList();
          _isLoading = false;
        });
        
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden von Erinnerungen: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _saveReminder(Map<String, dynamic> reminder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reminders');

      if (reminder['id'] != null) {
        // Update existing reminder
        await ref.doc(reminder['id']).update({
          'title': reminder['title'],
          'time': reminder['time'],
          'isActive': reminder['isActive'],
        });
      } else {
        // Create new reminder
        final docRef = await ref.add({
          'title': reminder['title'],
          'time': reminder['time'],
          'isActive': reminder['isActive'],
        });
        reminder['id'] = docRef.id;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _addReminder() async {
    final titleController = TextEditingController();
    DateTime selectedTime = DateTime.now();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Neue Erinnerung',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2d3748),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF667eea),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alarm, color: Color(0xFF667eea)),
                    hintText: 'Titel der Erinnerung',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: const Color(0xFF2d3748),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedTime),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF667eea),
                            surface: Color(0xFF2d3748),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setDialogState(() {
                      final now = DateTime.now();
                      selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF667eea)),
                      const SizedBox(width: 12),
                      Text(
                        'Zeit: ${DateFormat('HH:mm').format(selectedTime)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'title': titleController.text.trim(),
                    'time': selectedTime,
                    'isActive': true,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hinzufügen',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _reminders.add(result);
      });
      await _saveReminder(result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Erinnerung erfolgreich hinzugefügt! ⏰'),
            ],
          ),
          backgroundColor: Color(0xFF43e97b),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeReminder(int index) async {
    final reminder = _reminders[index];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Erinnerung löschen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchten Sie die Erinnerung "${reminder['title']}" wirklich löschen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && reminder['id'] != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('reminders')
              .doc(reminder['id'])
              .delete();
        }
        
        setState(() {
          _reminders.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('Erinnerung gelöscht! 🗑️'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(int index) async {
    final reminder = _reminders[index];
    setState(() {
      _reminders[index]['isActive'] = !_reminders[index]['isActive'];
    });
    await _saveReminder(_reminders[index]);
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
                            if (_errorMessage != null) _buildErrorMessage(),
                            _buildHeader(isTablet),
                            const SizedBox(height: 30),
                            _buildRemindersList(isTablet),
                            const SizedBox(height: 30),
                            _buildAddButton(isTablet),
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
            'Erinnerungen',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alarm,
              color: Colors.white,
              size: isTablet ? 40 : 32,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Ihre Erinnerungen',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            '${_reminders.length} Erinnerung${_reminders.length != 1 ? 'en' : ''} konfiguriert',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(bool isTablet) {
    if (_reminders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 60 : 40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.alarm_off,
              size: isTablet ? 80 : 60,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'Keine Erinnerungen',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Fügen Sie Ihre erste Erinnerung hinzu',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _reminders.asMap().entries.map((entry) {
        final index = entry.key;
        final reminder = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildReminderCard(reminder, index, isTablet),
        );
      }).toList(),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, int index, bool isTablet) {
    final isActive = reminder['isActive'] ?? true;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isActive
              ? [
                  const Color(0xFF2d3748),
                  const Color(0xFF1a202c),
                ]
              : [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                    : [Colors.grey.withOpacity(0.6), Colors.grey.withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.alarm,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'] ?? 'Unbenannte Erinnerung',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isTablet ? 18 : 16,
                      color: isActive ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(reminder['time']),
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: isActive ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) => _toggleReminder(index),
            activeColor: const Color(0xFF43e97b),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeReminder(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 60 : 55,
      child: ElevatedButton(
        onPressed: _addReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_alarm,
                  color: Colors.white,
                  size: isTablet ? 24 : 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Neue Erinnerung hinzufügen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
