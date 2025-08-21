import 'package:flutter/foundation.dart';

class DietLogModel {
  final int? id;              // 서버가 넣어줄 수도, 없을 수도 있으니 옵셔널
  final DateTime date;        // 화면에서 DateTime으로 사용
  final String mealType;      // '아침' | '점심' | '저녁'
  final String mainDish;
  final String? subDish;
  final int? proteinGrams;    // 단백질량 필드 추가

  DietLogModel({
    this.id,
    required this.date,
    required this.mealType,
    required this.mainDish,
    this.subDish,
    this.proteinGrams,        // 생성자에 추가
  });

  factory DietLogModel.fromJson(Map<String, dynamic> json) {
    // 서버가 date를 'yyyy-MM-dd' 또는 ISO로 줄 수 있으니 양쪽 다 커버
    final rawDate = json['date'];
    DateTime parsedDate;
    if (rawDate is String) {
      // '2025-08-11' 또는 '2025-08-11T00:00:00Z'
      parsedDate = DateTime.tryParse(rawDate) ??
          DateTime.tryParse('${rawDate}T00:00:00') ??
          DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return DietLogModel(
      id: (json['id'] as num?)?.toInt(),
      date: parsedDate,
      mealType: (json['mealType'] as String?) ?? '',
      mainDish: (json['mainDish'] as String?) ?? '',
      subDish: json['subDish'] as String?,
      proteinGrams: (json['proteinGrams'] as num?)?.toInt(), // proteinGrams 파싱
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    // 서버가 'yyyy-MM-dd' 형식을 기대한다면 이렇게 보냄
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return {
      'date': '$y-$m-$d',
      'mealType': mealType,
      'mainDish': mainDish,
      'subDish': subDish,
      'proteinGrams': proteinGrams, // proteinGrams 추가
    };
  }
}
