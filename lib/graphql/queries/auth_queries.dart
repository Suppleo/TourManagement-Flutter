const String queryMe = r'''
  query {
    me {
      id       
      email
      role
    }
  }
''';

const String queryUsers = r'''
  query {
    users {
      id
      email
      role
      status
      lastLogin
      createdAt
      updatedAt
    }
  }
''';
