// 1) สถานะ + สี
import 'package:flutter/material.dart';

enum SlotStatus { free, occupied, reserved, disabled }

extension SlotStatusX on SlotStatus {
  String get apiValue => switch (this) {
    SlotStatus.free => 'FREE',
    SlotStatus.occupied => 'OCCUPIED',
    SlotStatus.reserved => 'RESERVED',
    SlotStatus.disabled => 'DISABLED',
  };

  Color get color => switch (this) {
    SlotStatus.free => Colors.green,
    SlotStatus.occupied => Colors.red,
    SlotStatus.reserved => Colors.yellow,
    SlotStatus.disabled => Colors.grey,
  };

  String get thai => switch (this) {
    SlotStatus.free => 'ว่าง',
    SlotStatus.occupied => 'ไม่ว่าง',
    SlotStatus.reserved => 'จอง',
    SlotStatus.disabled => 'ไม่พร้อมใช้งาน'
  };

  static SlotStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'FREE': return SlotStatus.free;
      case 'OCCUPIED': return SlotStatus.occupied;
      case 'RESERVED': return SlotStatus.reserved;
      case 'DISABLED': return SlotStatus.disabled;
      default: throw Exception('Unknown status: $s');
    }
  }
}
