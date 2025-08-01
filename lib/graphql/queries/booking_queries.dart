const String queryBookings = r'''
  query {
    bookings {
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

const String queryBookingById = r'''
  query Booking($id: ID!) {
    booking(id: $id) {
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