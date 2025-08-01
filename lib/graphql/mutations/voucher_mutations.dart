const String mutationCreateVoucher = r'''
mutation CreateVoucher(
  $code: String!
  $type: String!
  $value: Float!
  $conditions: String
  $validFrom: DateTime
  $validTo: DateTime
  $status: String
) {
  createVoucher(
    code: $code
    type: $type
    value: $value
    conditions: $conditions
    validFrom: $validFrom
    validTo: $validTo
    status: $status
  ) {
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

const String mutationUpdateVoucher = r'''
mutation UpdateVoucher(
  $id: ID!
  $code: String
  $type: String
  $value: Float
  $conditions: String
  $validFrom: DateTime
  $validTo: DateTime
  $status: String
) {
  updateVoucher(
    id: $id
    code: $code
    type: $type
    value: $value
    conditions: $conditions
    validFrom: $validFrom
    validTo: $validTo
    status: $status
  ) {
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

const String mutationDeleteVoucher = r'''
mutation DeleteVoucher($id: ID!) {
  deleteVoucher(id: $id)
}
''';