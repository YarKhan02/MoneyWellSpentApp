import 'package:flutter/material.dart';
import 'tokens.dart';

/// The fixed icon set a category's `icon_key` indexes into.
/// Order is persisted in the database, so entries are append-only.
const categoryIcons = [
  Icons.restaurant_outlined,
  Icons.shopping_basket_outlined,
  Icons.directions_bus_outlined,
  Icons.shopping_bag_outlined,
  Icons.receipt_long_outlined,
  Icons.favorite_border,
  Icons.movie_outlined,
  Icons.category_outlined,
];

/// Human-readable labels for [categoryIcons], used as icon semantics.
const categoryIconLabels = [
  'Food',
  'Groceries',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Entertainment',
  'Other',
];

/// The accent keys a category's `color_key` may hold. These are the stored
/// values and must not change; [categoryColorNames] supplies what people see.
const categoryColorKeys = ['forest', 'wheat', 'cherry'];

/// Readable names for the accent keys above.
const categoryColorNames = <String, String>{
  'forest': 'Forest green',
  'wheat': 'Wheat gold',
  'cherry': 'Cherry red',
};

String categoryColorName(String key) => categoryColorNames[key] ?? key;

IconData categoryIcon(String key) =>
    categoryIcons[(int.tryParse(key) ?? 7).clamp(0, 7)];

Color categoryColor(String key) => switch (key) {
  'wheat' => Brand.wheat,
  'cherry' => Brand.cherry,
  _ => Brand.forest,
};
