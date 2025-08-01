const String queryTours = r'''
  query {
    tours {
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

const String queryTourById = r'''
  query Tour($id: ID!) {
    tour(id: $id) {
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

const String searchToursByLocationQuery = r'''
  query SearchToursByLocation($location: String!) {
    searchTours(location: $location) {
      id
      title
      price
      location
      description
    }
  }
''';
