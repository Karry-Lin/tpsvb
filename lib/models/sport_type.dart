/// 運動類型
class SportType {
  final String id; // categoryId，例：Badminton
  final String name; // 中文名稱，例：羽球

  const SportType({required this.id, required this.name});

  static const List<SportType> all = [
    SportType(id: 'Badminton', name: '羽球'),
    SportType(id: 'Basketball', name: '籃球'),
    SportType(id: 'Billiard', name: '撞球'),
    SportType(id: 'Golf', name: '高爾夫球'),
    SportType(id: 'Squash', name: '壁球'),
    SportType(id: 'TableTennis', name: '桌球'),
  ];
}
