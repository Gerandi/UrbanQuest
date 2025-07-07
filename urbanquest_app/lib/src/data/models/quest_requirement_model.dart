import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum QuestRequirementType {
  goodShoes('good_shoes', 'Good Shoes', Icons.directions_walk),
  water('water', 'Water', Icons.water_drop_outlined),
  chargedPhone('charged_phone', 'Charged Phone', Icons.battery_charging_full),
  camera('camera', 'Camera', Icons.camera_alt_outlined),
  sunscreen('sunscreen', 'Sunscreen', Icons.wb_sunny_outlined),
  hat('hat', 'Hat/Cap', Icons.emoji_objects_outlined),
  snacks('snacks', 'Snacks', Icons.fastfood_outlined),
  notebook('notebook', 'Notebook', Icons.book_outlined),
  pen('pen', 'Pen/Pencil', Icons.edit_outlined),
  flashlight('flashlight', 'Flashlight', Icons.flashlight_on_outlined),
  firstAid('first_aid', 'First Aid', Icons.medical_services_outlined),
  umbrella('umbrella', 'Umbrella', Icons.umbrella_outlined),
  jacket('jacket', 'Jacket', Icons.checkroom_outlined),
  backpack('backpack', 'Backpack', Icons.backpack_outlined),
  tickets('tickets', 'Tickets/ID', Icons.confirmation_number_outlined);

  const QuestRequirementType(this.id, this.displayName, this.icon);
  
  final String id;
  final String displayName;
  final IconData icon;
  
  static QuestRequirementType? fromId(String id) {
    try {
      return QuestRequirementType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}

class QuestRequirement extends Equatable {
  final QuestRequirementType type;
  final bool isRequired;
  final String? customNote;

  const QuestRequirement({
    required this.type,
    this.isRequired = true,
    this.customNote,
  });

  factory QuestRequirement.fromJson(Map<String, dynamic> json) {
    final type = QuestRequirementType.fromId(json['type'] as String);
    if (type == null) {
      throw ArgumentError('Invalid requirement type: ${json['type']}');
    }
    
    return QuestRequirement(
      type: type,
      isRequired: json['is_required'] as bool? ?? true,
      customNote: json['custom_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.id,
      'is_required': isRequired,
      'custom_note': customNote,
    };
  }

  @override
  List<Object?> get props => [type, isRequired, customNote];
}