const String queryCategories = r'''
  query {
    categories {
      id
      name
      description
    }
  }
''';

const String queryCategoryById = r'''
  query Category($id: ID!) {
    category(id: $id) {
      id
      name
      description
    }
  }
''';