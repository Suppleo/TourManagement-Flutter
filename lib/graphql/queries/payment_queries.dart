const String queryPayments = r'''
  query {
    payments {
      id
      method
      amount
      status
      transactionId
      createdAt
    }
  }
''';

const String queryPaymentById = r'''
  query Payment($id: ID!) {
    payment(id: $id) {
      id
      method
      amount
      status
      transactionId
      createdAt
    }
  }
''';