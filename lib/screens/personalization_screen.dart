import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/motivational_quotes.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  bool _quotesEnabled = true;
  String _currentQuote = '';

  @override
  void initState() {
    super.initState();
    _loadQuoteSettings();
  }

  Future<void> _loadQuoteSettings() async {
    final enabled = await MotivationalQuotes.isQuotesEnabled();
    final quote = await MotivationalQuotes.getSavedQuote();
    setState(() {
      _quotesEnabled = enabled;
      _currentQuote = quote;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalisierung'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Darstellung'),
                const SizedBox(height: 16),
                
                // Theme Mode
                _buildCard(
                  title: 'Erscheinungsbild',
                  subtitle: 'Wählen Sie zwischen Hell, Dunkel oder System',
                  icon: Icons.brightness_6,
                  child: _buildThemeModeSelector(themeProvider),
                ),
                
                const SizedBox(height: 16),
                
                // Color Theme
                _buildCard(
                  title: 'Farbschema',
                  subtitle: 'Wählen Sie Ihre bevorzugte Farbe',
                  icon: Icons.palette,
                  child: _buildColorSelector(themeProvider),
                ),
                
                const SizedBox(height: 16),
                

                
                const SizedBox(height: 24),
                
                _buildSectionTitle('Motivation'),
                const SizedBox(height: 16),
                
                // Motivational Quotes
                _buildCard(
                  title: 'Motivationszitate',
                  subtitle: 'Tägliche inspirierende Nachrichten',
                  icon: Icons.format_quote,
                  child: _buildMotivationalQuotesSection(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildRadioTile(
          title: 'System',
          subtitle: 'Folgt den Systemeinstellungen',
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (value) { if (value != null) themeProvider.setThemeMode(value); },
        ),
        _buildRadioTile(
          title: 'Hell',
          subtitle: 'Immer helles Design',
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (value) { if (value != null) themeProvider.setThemeMode(value); },
        ),
        _buildRadioTile(
          title: 'Dunkel',
          subtitle: 'Immer dunkles Design',
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (value) { if (value != null) themeProvider.setThemeMode(value); },
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildColorSelector(ThemeProvider themeProvider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ThemeProvider.availableColors.entries.map((entry) {
        final isSelected = themeProvider.primaryColor == entry.value;
        return GestureDetector(
          onTap: () => themeProvider.setPrimaryColor(entry.key),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: entry.value.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }



  Widget _buildMotivationalQuotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _quotesEnabled ? 'Motivationszitate aktiviert' : 'Motivationszitate deaktiviert',
                style: TextStyle(
                  fontSize: 14,
                  color: _quotesEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ),
            Switch(
              value: _quotesEnabled,
              onChanged: (value) async {
                await MotivationalQuotes.setQuotesEnabled(value);
                setState(() {
                  _quotesEnabled = value;
                });
              },
            ),
          ],
        ),
        if (_quotesEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentQuote,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newQuote = MotivationalQuotes.getRandomQuote('de');
                    await MotivationalQuotes.saveQuote(newQuote);
                    setState(() {
                      _currentQuote = newQuote;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Neues Zitat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _quotesEnabled 
            ? 'Diese Zitate werden täglich in der Stimmungsverfolgung angezeigt.'
            : 'Aktivieren Sie Motivationszitate, um täglich inspirierende Nachrichten zu erhalten.',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
} 