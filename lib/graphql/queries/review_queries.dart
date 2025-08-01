// review_queries.dart

const String queryReviews = r'''
  query Reviews($tour: ID) {
    reviews(tour: $tour) {
      id
      rating
      comment
      status
      reply
      images
      tour {
        id
        title
      }
      user {
        id         # ✅ Đã thêm dòng này để sửa lỗi user.id == null
        email
      }
    }
  }
''';

const String queryReviewById = r'''
  query Review($id: ID!) {
    review(id: $id) {
      id
      rating
      comment
      status
      reply
      images
      tour {
        id
        title
      }
      user {
        id
        email
      }
    }
  }
''';
