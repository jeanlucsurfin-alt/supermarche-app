import 'package:flutter/material.dart';

/// Icônes disponibles pour les catégories, indexées par clé stable
/// (la clé est stockée en base ; l'IconData ne l'est pas directement).
const Map<String, IconData> categoryIconChoices = {
  'grocery': Icons.local_grocery_store_rounded,
  'spa': Icons.spa_rounded,
  'clothing': Icons.checkroom_rounded,
  'electronics': Icons.devices_rounded,
  'home': Icons.chair_rounded,
  'toys': Icons.toys_rounded,
  'books': Icons.menu_book_rounded,
  'tools': Icons.handyman_rounded,
  'food': Icons.restaurant_rounded,
  'sports': Icons.sports_basketball_rounded,
  'health': Icons.favorite_rounded,
  'baby': Icons.child_care_rounded,
  'pets': Icons.pets_rounded,
  'stationery': Icons.edit_note_rounded,
  'other': Icons.inventory_2_rounded,
};

/// Couleurs disponibles pour les catégories.
const List<int> categoryColorChoices = [
  0xFF1F9D55, // vert
  0xFFD6559D, // rose
  0xFF2F6FED, // bleu
  0xFF6B5CE0, // violet
  0xFFC97A3D, // orange
  0xFF17A2A2, // sarcelle
  0xFFE0483E, // rouge
  0xFF3F51B5, // indigo
  0xFF8D6E63, // marron
  0xFF14264A, // marine
];

IconData iconForKey(String key) {
  return categoryIconChoices[key] ?? Icons.inventory_2_rounded;
}
