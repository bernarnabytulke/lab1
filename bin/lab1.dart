// Лабораторна робота 1. Функції та обробка колекцій.
// Варіант 11. Предметна область: показання лічильників.
// Класи не використовуються: дані — записи, обробка — функції.

/// Одне показання лічильника.
typedef Reading = ({
  DateTime date,
  String service,
  double previous,
  double current,
  double tariff,
  String meter,
});

/// Результат розбору: або показання, або опис помилки.
typedef ParseResult = ({Reading? reading, String? error});

/// Формат рядка: дата;послуга;попереднє;поточне;тариф;номер лічильника
const rawData = <String>[
  '2024-01-31;Електроенергія;12000.0;12150.5;4.32;EL-100231',
  '2024-02-29;Електроенергія;12150.5;12290.0;4.32;EL-100231',
  '2024-03-31;Електроенергія;12290.0;12410.0;4.32;EL-100231',
  '2024-04-30;Електроенергія;12410.0;12500.0;4.32;EL-100231',
  '2024-01-31;Вода;350.2;358.7;42.50;WT-204518',
  '2024-02-29;Вода;358.7;366.1;42.50;WT-204518',
  '2024-03-31;Вода;366.1;373.9;42.50;WT-204518',
  '2024-04-30;Вода;373.9;380.2;42.50;WT-204518',
  '2024-01-31;Газ;800.0;880.0;7.96;GS-310774',
  '2024-02-29;Газ;880.0;950.0;7.96;GS-310774',
  '2024-03-31;Газ;950.0;1000.0;7.96;GS-310774',
  '2024-04-30;Газ;1000.0;1030.0;7.96;GS-310774',
  '2024-01-31;Опалення;45.0;52.0;1900.00;HT-408812',
  '2024-02-29;Опалення;52.0;61.5;1900.00;HT-408812',
  '2024-03-31;Опалення;61.5;68.0;1900.00;HT-408812',
  // Пошкоджені рядки:
  '2024-05-31;Вода;380.2;388.0', // відсутні поля
  '2024-05-31;Газ;1030.0;багато;7.96;GS-310774', // нечислове значення
  '31.05.2024;Електроенергія;12500.0;12600.0;4.32;EL-100231', // дата
  // Розібраний, але не пройде валідацію:
  '2024-05-31;Електроенергія;12600.0;12400.0;-4.32;el-1',
];

final meterPattern = RegExp(r'^(?<kind>[A-Z]{2})-(?<number>\d{6})$');
final _maskPattern = RegExp(r'(?<head>[A-Z]{2}-\d{2})\d{4}');

/// Розбирає рядок [line] у показання. Без try/catch: використовується tryParse.
ParseResult parseLine(String line) {
  final parts = line.split(';').map((p) => p.trim()).toList();
  if (parts.length != 6) {
    return (reading: null, error: 'Очікувалось 6 полів, знайдено ${parts.length}');
  }
  final date = DateTime.tryParse(parts[0]);
  if (date == null) {
    return (reading: null, error: 'Некоректна дата "${parts[0]}"');
  }
  if (parts[1].isEmpty) {
    return (reading: null, error: 'Порожній тип послуги');
  }
  final previous = double.tryParse(parts[2]);
  if (previous == null) {
    return (reading: null, error: 'Попереднє значення "${parts[2]}" не є числом');
  }
  final current = double.tryParse(parts[3]);
  if (current == null) {
    return (reading: null, error: 'Поточне значення "${parts[3]}" не є числом');
  }
  final tariff = double.tryParse(parts[4]);
  if (tariff == null) {
    return (reading: null, error: 'Тариф "${parts[4]}" не є числом');
  }
  return (
    reading: (
      date: date,
      service: parts[1],
      previous: previous,
      current: current,
      tariff: tariff,
      meter: parts[5],
    ),
    error: null,
  );
}

String formatDate(DateTime d) => d.toIso8601String().substring(0, 10);

/// Перевіряє діапазони значень і повертає перелік порушень.
List<String> validate(Reading r, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return [
    if (!meterPattern.hasMatch(r.meter))
      'Номер лічильника "${r.meter}" не відповідає формату',
    if (r.date.year < 2000 || r.date.isAfter(today))
      'Дата ${formatDate(r.date)} поза допустимим діапазоном',
    if (r.previous < 0) 'Попереднє значення ${r.previous} від’ємне',
    if (r.current < r.previous)
      'Поточне (${r.current}) менше за попереднє (${r.previous})',
    if (r.tariff <= 0) 'Тариф ${r.tariff} має бути додатним',
  ];
}

/// Спожито за період.
double consumption(Reading r) => r.current - r.previous;

/// Вартість = спожито × тариф.
double cost(Reading r) => consumption(r) * r.tariff;

/// Загальна вартість (fold).
double totalCost(List<Reading> items) =>
    items.fold(0.0, (sum, r) => sum + cost(r));

/// Групує показання за типом послуги.
Map<String, List<Reading>> groupByService(List<Reading> items) {
  final result = <String, List<Reading>>{};
  for (final r in items) {
    result.putIfAbsent(r.service, () => []).add(r);
  }
  return result;
}
