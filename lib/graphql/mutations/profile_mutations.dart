const String updateMyProfileMutation = r'''
  mutation UpdateMyProfile($input: ProfileInput!) {
    updateMyProfile(input: $input) {
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

const String createProfileMutation = r'''
  mutation CreateProfile($userId: ID!, $input: ProfileInput!) {
    createProfile(userId: $userId, input: $input) {
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

const String deleteMyProfileMutation = r'''
  mutation {
    deleteMyProfile
  }
''';
