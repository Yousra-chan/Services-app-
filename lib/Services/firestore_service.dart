import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/screens/posts/posts_constants.dart';

class FirestoreService {
  // Reference to the 'posts' collection in Firestore
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');

  // 1. CREATE: Add a new post
  Future<void> addPost(Post post) async {
    try {
      await _postsCollection.add(post.toMap());
    } catch (e) {
      print("Error adding post: $e");
      rethrow;
    }
  }

  // 2. READ: Get a Stream of Posts (Real-time updates)
  Stream<List<Post>> getPostsStream() {
    return _postsCollection
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
