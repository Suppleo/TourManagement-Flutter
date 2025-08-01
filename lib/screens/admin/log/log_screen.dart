import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/log_provider.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LogProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thao tác')),
      body: FutureBuilder(
        future: provider.fetchLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

          return ListView.builder(
            itemCount: provider.logs.length,
            itemBuilder: (context, index) {
              final log = provider.logs[index];
              return ListTile(
                title: Text(log.action),
                subtitle: Text('Thời gian: ${log.createdAt ?? 'N/A'}'),
              );
            },
          );
        },
      ),
    );
  }
}
