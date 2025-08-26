// 1) สถานะ + สี
import 'package:flutter/material.dart';

enum SlotStatus { free, occupied, reserved, disabled }

enum ReservStatus { confirmed, cancelled, expired, used }

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
    SlotStatus.disabled => 'ไม่พร้อมใช้งาน',
  };

  static SlotStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'FREE':
        return SlotStatus.free;
      case 'OCCUPIED':
        return SlotStatus.occupied;
      case 'RESERVED':
        return SlotStatus.reserved;
      case 'DISABLED':
        return SlotStatus.disabled;
      default:
        throw Exception('Unknown status: $s');
    }
  }
}

extension ReservStatusX on ReservStatus {
  String get apiValue => switch (this) {
    ReservStatus.confirmed => 'CONFIRMED',
    ReservStatus.cancelled => 'CANCELLED',
    ReservStatus.expired => 'EXPIRED',
    ReservStatus.used => 'USED',
  };

  String get thai => switch (this) {
    ReservStatus.confirmed => 'จองสำเร็จ',
    ReservStatus.cancelled => 'ยกเลิก',
    ReservStatus.expired => 'หมดอายุ',
    ReservStatus.used => 'ใช้แล้ว',
  };

  static ReservStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'CONFIRMED':
        return ReservStatus.confirmed;
      case 'CANCELLED':
        return ReservStatus.cancelled;
      case 'EXPIRED':
        return ReservStatus.expired;
      case 'USED':
        return ReservStatus.used;
      default:
        throw Exception('Unknown status: $s');
    }
  }
}
