// review_mutations.dart

const String mutationCreateReview = r'''
  mutation CreateReview($tour: ID!, $rating: Int!, $comment: String, $images: [String!]) {
    createReview(tour: $tour, rating: $rating, comment: $comment, images: $images) {
      id
      rating
      comment
      status
      images
    }
  }
''';

const String mutationUpdateReview = r'''
  mutation UpdateReview($id: ID!, $rating: Int, $comment: String, $status: String, $images: [String!]) {
    updateReview(id: $id, rating: $rating, comment: $comment, status: $status, images: $images) {
      id
      rating
      comment
      status
      images
      reply
    }
  }
''';

const String mutationDeleteReview = r'''
  mutation DeleteReview($id: ID!) {
    deleteReview(id: $id)
  }
''';

const String mutationReplyReview = r'''
  mutation ReplyReview($id: ID!, $reply: String!) {
    replyReview(id: $id, reply: $reply) {
      id
      reply
    }
  }
''';
