import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _zielController = TextEditingController();
  final _zielKcalController = TextEditingController();
  final _zielSleepController = TextEditingController();
  final _zielWaterController = TextEditingController();
  final _zielStepsController = TextEditingController();
  String _email = '';
  String _gender = 'Männlich';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 30));
  double _weight = 70.0;
  double _height = 175.0;
  String _location = '';
  String? _ziel;
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = true;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _zielController.dispose();
    _zielKcalController.dispose();
    _zielSleepController.dispose();
    _zielWaterController.dispose();
    _zielStepsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          final data = userData.data()!;
          setState(() {
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _email = data['email'] ?? user.email ?? '';
            _gender = data['gender'] ?? 'Männlich';
            _birthDate = (data['birthDate'] as Timestamp?)?.toDate() ?? _birthDate;
            _weight = (data['weight'] ?? 70.0).toDouble();
            _height = (data['height'] ?? 175.0).toDouble();
            _profileImageUrl = data['profileImageUrl'];
            _ziel = data['ziel'];
            _location = data['location'] ?? '';
            _zielKcalController.text = (data['zielKcal'] ?? 2000).toString();
            _zielSleepController.text = (data['zielSleep'] ?? 8).toString();
            _zielWaterController.text = (data['zielWater'] ?? 2).toString();
            _zielStepsController.text = (data['zielSteps'] ?? 10000).toString();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header avec photo, nom, prénom, âge, poids, objectif
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_firstNameController.text} ${_lastNameController.text}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text('Alter: ${_calculateAge(_birthDate)}'),
                          Text('Gewicht: ${_weight.toStringAsFixed(1)} kg'),
                          Text('Ziel: ${_ziel ?? "-"}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Affichage et édition des objectifs (Ziele)
            Card(
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ziele', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _zielKcalController,
                      decoration: const InputDecoration(
                        labelText: 'Kalorien (kcal/Tag)',
                        prefixIcon: Icon(Icons.local_fire_department),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _zielSleepController,
                      decoration: const InputDecoration(
                        labelText: 'Schlaf (h/Tag)',
                        prefixIcon: Icon(Icons.bedtime),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _zielWaterController,
                      decoration: const InputDecoration(
                        labelText: 'Wasser (L/Tag)',
                        prefixIcon: Icon(Icons.opacity),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _zielStepsController,
                      decoration: const InputDecoration(
                        labelText: 'Ziel Schritte (pro Tag)',
                        prefixIcon: Icon(Icons.directions_walk),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'zielKcal': int.tryParse(_zielKcalController.text) ?? 2000,
                              'zielSleep': double.tryParse(_zielSleepController.text) ?? 8.0,
                              'zielWater': double.tryParse(_zielWaterController.text) ?? 2.0,
                              'zielSteps': int.tryParse(_zielStepsController.text) ?? 10000,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ziele gespeichert!')),
                              );
                            }
                          }
                        },
                        child: const Text('Speichern'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Sections
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.blue),
              title: const Text('Konto'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KontoEditScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Benutzer'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BenutzerEditScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Pages de modification vides ---
class KontoEditScreen extends StatefulWidget {
  const KontoEditScreen({super.key});

  @override
  State<KontoEditScreen> createState() => _KontoEditScreenState();
}

class _KontoEditScreenState extends State<KontoEditScreen> {
  final _emailController = TextEditingController();
  final _zielController = TextEditingController();
  final _zielKcalController = TextEditingController();
  final _zielSleepController = TextEditingController();
  final _zielWaterController = TextEditingController();
  final _zielStepsController = TextEditingController();
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 30));
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists) {
          final data = userData.data()!;
          setState(() {
            _emailController.text = data['email'] ?? user.email ?? '';
            _zielController.text = data['ziel'] ?? '';
            _birthDate = (data['birthDate'] as Timestamp?)?.toDate() ?? _birthDate;
            _zielKcalController.text = (data['zielKcal'] ?? 2000).toString();
            _zielSleepController.text = (data['zielSleep'] ?? 8).toString();
            _zielWaterController.text = (data['zielWater'] ?? 2).toString();
            _zielStepsController.text = (data['zielSteps'] ?? 10000).toString();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Daten.';
      });
    }
  }

  Future<void> _saveKonto() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'email': _emailController.text.trim(),
          'ziel': _zielController.text.trim(),
          'birthDate': _birthDate,
          'zielKcal': int.tryParse(_zielKcalController.text) ?? 2000,
          'zielSleep': double.tryParse(_zielSleepController.text) ?? 8.0,
          'zielWater': double.tryParse(_zielWaterController.text) ?? 2.0,
          'zielSteps': int.tryParse(_zielStepsController.text) ?? 10000,
        });
        setState(() => _isLoading = false);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Speichern.';
      });
    }
  }

  Future<void> _changePassword() async {
    // Envoie un email de réinitialisation du mot de passe
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Mail zum Zurücksetzen gesendet.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto bearbeiten'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _zielController,
                    decoration: const InputDecoration(
                      labelText: 'Ziel',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd.MM.yyyy').format(_birthDate)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Passwort vergessen ?'),
                    onPressed: _changePassword,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveKonto,
                      child: const Text('Speichern', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class BenutzerEditScreen extends StatefulWidget {
  const BenutzerEditScreen({super.key});

  @override
  State<BenutzerEditScreen> createState() => _BenutzerEditScreenState();
}

class _BenutzerEditScreenState extends State<BenutzerEditScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _locationController = TextEditingController();
  double _height = 175.0;
  double _weight = 70.0;
  String _gender = 'Männlich';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists) {
          final data = userData.data()!;
          setState(() {
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _locationController.text = data['location'] ?? '';
            _height = (data['height'] ?? 175.0).toDouble();
            _weight = (data['weight'] ?? 70.0).toDouble();
            _gender = data['gender'] ?? 'Männlich';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden von Daten.';
      });
    }
  }

  Future<void> _saveBenutzer() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'location': _locationController.text.trim(),
          'height': _height,
          'weight': _weight,
          'gender': _gender,
        });
        setState(() => _isLoading = false);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Speichern.';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzer bearbeiten'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vorname',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nachname',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Wohnort',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _height.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Größe (cm)',
                            prefixIcon: Icon(Icons.height),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _height = double.tryParse(value) ?? _height,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: _weight.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Gewicht (kg)',
                            prefixIcon: Icon(Icons.monitor_weight),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _weight = double.tryParse(value) ?? _weight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Geschlecht',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                ),
                items: ['Männlich', 'Weiblich', 'Andere']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveBenutzer,
                      child: const Text('Speichern', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}