// import 'package:hive/hive.dart';

// part 'task.g.dart';

// @HiveType(typeId: 0)
// class Task extends HiveObject {
//   @HiveField(0)
//   String title;

//   @HiveField(1)
//   bool isDone;

//   Task({required this.title, this.isDone = false});
// }


import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  @HiveField(2)
  bool isSynced;

  Task({
    required this.title,
    this.isDone = false,
    this.isSynced = false,
  });
}
