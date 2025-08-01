import 'package:flutter/material.dart';
import '../models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(user.email),
        subtitle: Text('Role: ${user.role} - Status: ${user.status}'),
        onTap: onTap,
      ),
    );
  }
}
