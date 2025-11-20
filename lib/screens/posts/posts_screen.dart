import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/Services/firestore_service.dart';
import 'posts_constants.dart';
import 'package:myapp/screens/posts/posts_widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 1. This is the function we will pass to the Modal
  void _handleCreatePost(Post post) async {
    try {
      await _firestoreService.addPost(post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    }
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // 2. FIX: We pass the function here to satisfy the 'required' parameter
        child: CreatePostModal(onPostCreated: _handleCreatePost),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Service Exchange Feed',
          style: TextStyle(
            color: kDarkTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kLightBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: kDarkTextColor),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: _firestoreService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No posts yet. Be the first!",
                style: TextStyle(color: kMutedTextColor, fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostModal,
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Post'),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
