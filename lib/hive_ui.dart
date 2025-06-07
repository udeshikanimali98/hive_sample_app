// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'task.dart';

// class HivePage extends StatelessWidget {
//   const HivePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Box<Task> taskBox = Hive.box<Task>('tasks');

//     return Scaffold(
//       appBar: AppBar(title: const Text('All Tasks with Sync Status')),
//       body: ValueListenableBuilder(
//         valueListenable: taskBox.listenable(),
//         builder: (context, Box<Task> box, _) {
//           final tasks = box.values.toList();

//           if (tasks.isEmpty) {
//             return const Center(child: Text('No tasks found'));
//           }

//           return ListView.builder(
//             itemCount: tasks.length,
//             itemBuilder: (context, index) {
//               final task = tasks[index];
//               return ListTile(
//                 title: Text(
//                   task.title,
//                   style: TextStyle(
//                     decoration:
//                         task.isDone ? TextDecoration.lineThrough : null,
//                   ),
//                 ),
//                 subtitle: Text(
//                   task.isSynced ? '✅ Synced' : '⚠️ Not Synced',
//                   style: TextStyle(
//                     color: task.isSynced ? Colors.green : Colors.red,
//                   ),
//                 ),
//                 trailing: Checkbox(
//                   value: task.isDone,
//                   onChanged: null, // read-only view
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task.dart';

class HivePage extends StatelessWidget {
  const HivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Task> taskBox = Hive.box<Task>('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final tasks = box.values.toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No tasks available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.isDone ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone ? Colors.grey.shade700 : Colors.black,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        task.isSynced ? Icons.cloud_done : Icons.cloud_off,
                        size: 18,
                        color: task.isSynced ? Colors.teal : Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.isSynced ? 'Synced' : 'Not Synced',
                        style: TextStyle(
                          fontSize: 14,
                          color: task.isSynced ? Colors.teal : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  tileColor: Colors.white,
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
