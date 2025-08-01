const String mutationRegister = r'''
  mutation Register($email: String!, $password: String!) {
    register(email: $email, password: $password) {
      token
      user {
        id       
        email
        role
      }
    }
  }
''';

const String mutationLogin = r'''
  mutation Login($email: String!, $password: String!) {
    login(email: $email, password: $password) {
      token
      user {
        id      
        email
        role
      }
    }
  }
''';

const String mutationUpdateUser = r'''
  mutation UpdateUser($id: ID!, $email: String, $password: String) {
    updateUser(id: $id, email: $email, password: $password) {
      id
      email
      role
      status
    }
  }
''';

const String mutationDeleteUser = r'''
  mutation DeleteUser($id: ID!) {
    deleteUser(id: $id)
  }
''';
