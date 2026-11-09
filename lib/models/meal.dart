class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.whyItHelps,
    required this.calories,
    required this.protein,
    this.type = 'Veg',
    this.isKeralaStyle = false,
    this.category = 'Lunch',
  });

  final String id;
  final String name;
  final String description;
  final String whyItHelps;
  final int calories;
  final int protein;
  final String type; // 'Veg' or 'Non-Veg'
  final bool isKeralaStyle;
  final String category; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'whyItHelps': whyItHelps,
      'calories': calories,
      'protein': protein,
      'type': type,
      'isKeralaStyle': isKeralaStyle ? 1 : 0,
      'category': category,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      whyItHelps: map['whyItHelps'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as int,
      type: map['type'] as String? ?? 'Veg',
      isKeralaStyle: (map['isKeralaStyle'] as int?) == 1,
      category: map['category'] as String? ?? 'Lunch',
    );
  }

  static List<Meal> defaultMeals() {
    return const [
      Meal(
        id: 'chickpea_bowl',
        name: 'Chickpea Power Bowl',
        description: 'Warm quinoa, roasted chickpeas, greens, and avocado.',
        whyItHelps: 'Balanced fiber and plant protein support blood sugar stability.',
        calories: 430,
        protein: 18,
      ),
      Meal(
        id: 'tofu_wrap',
        name: 'Tofu Veggie Wrap',
        description: 'Crispy tofu with mixed greens, hummus, and crunchy vegetables.',
        whyItHelps: 'Protein-rich and low glycemic for steady energy and satiety.',
        calories: 390,
        protein: 22,
      ),
      Meal(
        id: 'lentil_soup',
        name: 'Lentil & Greens Soup',
        description: 'Slow-cooked lentils with spinach, herbs, and turmeric.',
        whyItHelps: 'High in fiber and anti-inflammatory nutrients to support digestion.',
        calories: 360,
        protein: 16,
      ),
      Meal(
        id: 'overnight_oats',
        name: 'Berry Overnight Oats',
        description: 'Oats with chia, flax, almond milk, and berries.',
        whyItHelps: 'Supports fullness and helps reduce insulin spikes.',
        calories: 320,
        protein: 12,
      ),
      Meal(
        id: 'greens_smoothie',
        name: 'Green Recovery Smoothie',
        description: 'Spinach, berries, chia, and unsweetened plant milk.',
        whyItHelps: 'Nutrient-dense and easy to digest after a busy day.',
        calories: 280,
        protein: 11,
      ),
      Meal(
        id: 'cauliflower_rice',
        name: 'Cauliflower Rice Stir-Fry',
        description: 'Tofu, edamame, cabbage, and cauliflower rice with ginger.',
        whyItHelps: 'Low-carb, high-fiber, and ideal for long-lasting energy.',
        calories: 410,
        protein: 20,
      ),
    ];
  }
}

class MealProgress {
  const MealProgress({
    required this.meal,
    required this.completed,
  });

  final Meal meal;
  final bool completed;
}

class DailyHistoryEntry {
  const DailyHistoryEntry({
    required this.date,
    required this.completedCount,
    required this.totalMeals,
  });

  final DateTime date;
  final int completedCount;
  final int totalMeals;

  double get completionPercent =>
      totalMeals == 0 ? 0 : (completedCount / totalMeals) * 100;
}
