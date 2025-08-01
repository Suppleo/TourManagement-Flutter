const String mutationCreateBooking = r'''
  mutation CreateBooking($input: BookingInput!) {
    createBooking(input: $input) {
      id
      tour { id title }
      user { id email }
      passengers { name age type }
      voucher
      paymentMethod
      status
      paymentStatus
    }
  }
''';

const String mutationUpdateBooking = r'''
  mutation UpdateBooking($id: ID!, $status: String, $paymentStatus: String) {
    updateBooking(id: $id, status: $status, paymentStatus: $paymentStatus) {
      id
      status
      paymentStatus
    }
  }
''';

const String mutationDeleteBooking = r'''
  mutation DeleteBooking($id: ID!) {
    deleteBooking(id: $id)
  }
''';