const String queryVouchers = r'''
  query {
    vouchers {
      id
      code
      type
      value
      conditions
      validFrom
      validTo
      status
      createdAt
      updatedAt
    }
  }
''';

const String queryVoucherById = r'''
  query Voucher($id: ID!) {
    voucher(id: $id) {
      id
      code
      type
      value
      conditions
      validFrom
      validTo
      status
      createdAt
      updatedAt
    }
  }
''';
