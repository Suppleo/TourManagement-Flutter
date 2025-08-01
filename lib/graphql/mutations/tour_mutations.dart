const String mutationCreateTour = r'''
  mutation CreateTour($input: TourInput!) {
    createTour(input: $input) {
      id
      title
      price
      itinerary
      servicesIncluded
      servicesExcluded
      cancelPolicy
      images
      videos
      location
      category {
        id
        name
      }
      status
      isDeleted
      version
      createdAt
      updatedAt
    }
  }
''';


const String mutationUpdateTour = r'''
  mutation UpdateTour($id: ID!, $input: TourUpdateInput!) {
    updateTour(id: $id, input: $input) {
      id
      title
      price
      itinerary
      servicesIncluded
      servicesExcluded
      cancelPolicy
      images
      videos
      location
      category {
        id
        name
      }
      status
      isDeleted
      version
      createdAt
      updatedAt
    }
  }
''';

const String mutationDeleteTour = r'''
  mutation DeleteTour($id: ID!) {
    deleteTour(id: $id)
  }
''';
