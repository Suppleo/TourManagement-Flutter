const String queryLogs = r'''
  query {
    logs {
      _id
      action
      createdAt
    }
  }
''';
