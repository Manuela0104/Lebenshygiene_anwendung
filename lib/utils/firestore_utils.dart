import 'package:cloud_firestore/cloud_firestore.dart';

// Cette map contient la structure de tes questions avant la modification
final Map<String, List<Map<String, dynamic>>> initialKategorienFragebogen = {
  'Ernährung': [
    {'text': 'Trinkst du genug Wasser?', 'type': 'boolean', 'order': 1, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie viele Mahlzeiten isst du pro Tag?', 'type': 'number', 'order': 2, 'scores': {}}, // Ajoutez des scores appropriés si nécessaire
    {'text': 'Isst du regelmäßig Obst und Gemüse?', 'type': 'boolean', 'order': 3, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft isst du Fast Food?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 4, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie viele Süßigkeiten isst du pro Woche?', 'type': 'number', 'order': 5, 'scores': {}}, // Ajoutez des scores
    {'text': 'Frühstückst du jeden Tag?', 'type': 'boolean', 'order': 6, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft trinkst du zuckerhaltige Getränke?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 7, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft isst du Fisch oder Meeresfrüchte?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 8, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft isst du Milchprodukte?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 9, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie viele Gläser Wasser trinkst du pro Tag?', 'type': 'number', 'order': 10, 'scores': {}}, // Ajoutez des scores
  ],
  'Training': [
    {'text': 'Wie oft trainierst du pro Woche?', 'type': 'number', 'order': 1, 'scores': {}}, // Ajoutez des scores
    {'text': 'Wie viele Minuten dauert dein Training im Durchschnitt?', 'type': 'number', 'order': 2, 'scores': {}}, // Ajoutez des scores
    {'text': 'Machst du Krafttraining?', 'type': 'boolean', 'order': 3, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Machst du Ausdauertraining?', 'type': 'boolean', 'order': 4, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Dehnst du dich nach dem Training?', 'type': 'boolean', 'order': 5, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft gehst du zu Fuß?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 6, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie viele Schritte machst du pro Tag?', 'type': 'number', 'order': 7, 'scores': {}}, // Ajoutez des scores
    {'text': 'Hast du einen Trainingsplan?', 'type': 'boolean', 'order': 8, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie motiviert bist du für Sport?', 'type': 'scale', 'labels': ['Gar nicht', 'Wenig', 'Mittel', 'Viel', 'Sehr viel'], 'order': 9, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Trainierst du lieber allein oder in der Gruppe?', 'type': 'scale', 'labels': ['Allein', 'Gruppe', 'Beides'], 'order': 10, 'scores': {'1': 1, '2': 2, '3': 3}}, // Ajoutez des scores
  ],
  'Körperliche Hygiene': [
    {'text': 'Wie oft duschst du pro Woche?', 'type': 'number', 'order': 1, 'scores': {}}, // Ajoutez des scores
    {'text': 'Putzt du dir regelmäßig die Zähne?', 'type': 'boolean', 'order': 2, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wechselst du regelmäßig deine Kleidung?', 'type': 'boolean', 'order': 3, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft wäschst du deine Hände am Tag?', 'type': 'number', 'order': 4, 'scores': {}}, // Ajoutez des scores
    {'text': 'Benutzt du Deo oder Parfüm?', 'type': 'boolean', 'order': 5, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft schneidest du deine Nägel?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 6, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft gehst du zum Zahnarzt?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Jährlich', 'Öfter'], 'order': 7, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4}}, // Ajoutez des scores
    {'text': 'Benutzt du Sonnencreme?', 'type': 'boolean', 'order': 8, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft wechselst du deine Bettwäsche?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Monatlich', 'Öfter'], 'order': 9, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4}}, // Ajoutez des scores
    {'text': 'Wie oft reinigst du dein Handy?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Monatlich', 'Öfter'], 'order': 10, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4}}, // Ajoutez des scores
  ],
  'Mentale Hygiene': [
    {'text': 'Wie gestresst fühlst du dich aktuell?', 'type': 'scale', 'labels': ['Gar nicht', 'Wenig', 'Mittel', 'Stark', 'Sehr stark'], 'order': 1, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Machst du regelmäßig Entspannungsübungen?', 'type': 'boolean', 'order': 2, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie zufrieden bist du mit deinem Leben?', 'type': 'scale', 'labels': ['Sehr unzufrieden', 'Unzufrieden', 'Neutral', 'Zufrieden', 'Sehr zufrieden'], 'order': 3, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Hast du jemanden, mit dem du über Probleme sprechen kannst?', 'type': 'boolean', 'order': 4, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft nimmst du dir Zeit für dich selbst?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 5, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft meditierst du?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 6, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft fühlst du dich überfordert?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 7, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Wie oft schläfst du schlecht?', 'type': 'scale', 'labels': ['Nie', 'Selten', 'Manchmal', 'Oft', 'Sehr oft'], 'order': 8, 'scores': {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5}},
    {'text': 'Hast du Hobbys, die dir Freude machen?', 'type': 'boolean', 'order': 9, 'scores': {'true': 1, 'false': 0}},
    {'text': 'Wie oft lachst du am Tag?', 'type': 'number', 'order': 10, 'scores': {}}, // Ajoutez des scores
  ],
};


Future<void> uploadQuestionsToFirestore() async {
  final firestore = FirebaseFirestore.instance;

  print("Starting upload of initial questions to Firestore...");

  try {
    for (var categoryEntry in initialKategorienFragebogen.entries) {
      String categoryName = categoryEntry.key;
      List<Map<String, dynamic>> questions = categoryEntry.value;

      // Crée un document pour la catégorie (si n'existe pas)
      await firestore.collection('questionnaires').doc(categoryName).set({});
      print("Created document for category: $categoryName");

      // Ajoute les questions comme documents dans la sous-collection 'questions'
      final categoryQuestionsCollection = firestore.collection('questionnaires').doc(categoryName).collection('questions');

      for (var questionData in questions) {
        // Utilise add() pour laisser Firestore générer un ID de document unique
        await categoryQuestionsCollection.add(questionData);
        // Optionally print something for each question added
        // print(" Added question: ${questionData['text']}");
      }
      print(" Uploaded ${questions.length} questions for category: $categoryName");
    }
    print("Initial questions uploaded to Firestore successfully!"); // Confirmation dans la console
  } catch (e) {
    print("Error uploading questions to Firestore: $e"); // Log the error
  }
}

// Pour exécuter cette fonction, tu peux l'appeler une fois.
// Par exemple, tu peux l'appeler temporairement dans la fonction main() après Firebase.initializeApp().
// Assure-toi de la commenter ou de la supprimer après la première exécution. 