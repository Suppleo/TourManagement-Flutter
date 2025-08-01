const String mutationCheckout = r'''
  mutation Checkout($bookingId: ID!, $method: String!) {
    checkout(bookingId: $bookingId, method: $method) {
      payment {
        id
        method
        amount
        status
      }
      payUrl
    }
  }
''';

const String mutationConfirmPayment = r'''
  mutation ConfirmPayment($paymentId: ID!, $transactionId: String!) {
    confirmPayment(paymentId: $paymentId, transactionId: $transactionId) {
      id
      method
      amount
      status
      transactionId
    }
  }
''';
