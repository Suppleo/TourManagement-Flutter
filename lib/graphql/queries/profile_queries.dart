const String getMyProfileQuery = r'''
  query {
    getMyProfile {
      id
      fullName
      gender
      dob
      address
      avatar
      identityNumber
      issuedDate
      issuedPlace
      nationality
      emergencyContact {
        name
        phone
        relationship
      }
    }
  }
''';

const String getProfileByUserQuery = r'''
  query GetProfileByUser($userId: ID!) {
    getProfileByUser(userId: $userId) {
      id
      fullName
      gender
      dob
      address
      avatar
      identityNumber
      issuedDate
      issuedPlace
      nationality
      emergencyContact {
        name
        phone
        relationship
      }
    }
  }
''';
