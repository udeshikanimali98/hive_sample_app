// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'task.dart';

// class TaskListPage extends StatefulWidget {
//   const TaskListPage({super.key});

//   @override
//   State<TaskListPage> createState() => _TaskListPageState();
// }

// class _TaskListPageState extends State<TaskListPage> {
//   final Box<Task> taskBox = Hive.box<Task>('tasks');

//   void _addOrEditTask({Task? task, required bool isEdit}) {
//     final controller = TextEditingController(text: task?.title ?? '');
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(isEdit ? 'Edit Task' : 'New Task'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(hintText: 'Enter task title'),
//           autofocus: true,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               final input = controller.text.trim();
//               if (input.isNotEmpty) {
//                 if (isEdit) {
//                   task!.title = input;
//                   task.save();
//                 } else {
//                   taskBox.add(Task(title: input));
//                 }
//               }
//               Navigator.of(context).pop();
//             },
//             child: Text(isEdit ? 'Update' : 'Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _toggleDone(Task task) {
//     task.isDone = !task.isDone;
//     task.save();
//   }

//   void _deleteTask(Task task) {
//     task.delete();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Offline Task Tracker Pro')),
//       body: ValueListenableBuilder(
//         valueListenable: taskBox.listenable(),
//         builder: (context, Box<Task> box, _) {
//           if (box.values.isEmpty) {
//             return const Center(child: Text('No tasks yet.'));
//           }
//           return ListView.builder(
//             itemCount: box.length,
//             itemBuilder: (context, index) {
//               final task = box.getAt(index)!;
//               return ListTile(
//                 title: Text(
//                   task.title,
//                   style: TextStyle(
//                     decoration: task.isDone ? TextDecoration.lineThrough : null,
//                   ),
//                 ),
//                 leading: Checkbox(
//                   value: task.isDone,
//                   onChanged: (_) => _toggleDone(task),
//                 ),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.edit, color: Colors.orange),
//                       onPressed: () => _addOrEditTask(task: task, isEdit: true),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _deleteTask(task),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _addOrEditTask(isEdit: false),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:sample_app/hive_ui.dart';
import 'dart:io';
import 'package:sample_app/task.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late Box<Task> taskBox;
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/'));

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncToServer(Task task) async {
    if (await checkInternetConnection()) {
      final data = {
        'title': task.title,
        'isDone': task.isDone,
      };
      final id = task.key.toString();

      try {
        await dio.put('/tasks/$id', data: data);
      } catch (_) {
        await dio.post('/tasks', data: {'id': id, ...data});
      }
    }
  }

  Future<void> syncAllTasksToServer() async {
    if (await checkInternetConnection()) {
      for (var task in taskBox.values) {
        await syncToServer(task);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All tasks synced to server')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  Future<void> downloadTasksFromServer() async {
    if (await checkInternetConnection()) {
      try {
        final response = await dio.get('/tasks');
        final List tasks = response.data;

        for (var item in tasks) {
          final task = Task(
            title: item['title'] ?? '',
            isDone: item['isDone'] ?? false,
          );
          final id = int.tryParse(item['id'].toString());

          if (id != null && taskBox.containsKey(id)) {
            await taskBox.put(id, task);
          } else {
            await taskBox.add(task);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloaded tasks from server')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download from server')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  void addTask(String title) async {
    final task = Task(title: title, isDone: false);
    final key = await taskBox.add(task);
    setState(() {});
    await syncToServer(taskBox.get(key)!);
  }

  void toggleTask(Task task) async {
    task.isDone = !task.isDone;
    await task.save();
    setState(() {});
    await syncToServer(task);
  }

  void editTask(Task task, String newTitle) async {
    task.title = newTitle;
    await task.save();
    setState(() {});
    await syncToServer(task);
  }

  void deleteTask(Task task) async {
    final id = task.key.toString();
    await task.delete();
    if (await checkInternetConnection()) {
      try {
        await dio.delete('/tasks/$id');
      } catch (_) {}
    }
    setState(() {});
  }

  void showTaskDialog({Task? task}) {
    final controller = TextEditingController(text: task?.title ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context);
                if (task == null) {
                  addTask(title);
                } else {
                  editTask(task, title);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = taskBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Task Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Download from Server',
            onPressed: downloadTasksFromServer,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync to Server',
            onPressed: syncAllTasksToServer,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: 'View Synced Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HivePage()),
              );
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks yet.'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (_) => toggleTask(task),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showTaskDialog(task: task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteTask(task),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
