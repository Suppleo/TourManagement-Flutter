const String mutationCreateCategory = r'''
  mutation CreateCategory($name: String!, $description: String) {
    createCategory(name: $name, description: $description) {
      id
      name
      description
    }
  }
''';

const String mutationUpdateCategory = r'''
  mutation UpdateCategory($id: ID!, $name: String, $description: String) {
    updateCategory(id: $id, name: $name, description: $description) {
      id
      name
      description
    }
  }
''';

const String mutationDeleteCategory = r'''
  mutation DeleteCategory($id: ID!) {
    deleteCategory(id: $id)
  }
''';