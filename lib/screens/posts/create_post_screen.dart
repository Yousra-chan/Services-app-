import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'posts_constants.dart';
import 'package:myapp/screens/posts/posts_widgets.dart';



class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

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
            onPressed: () {
              // Handle search action
            },
          ),
        ],
      ),

      // Use ListView.builder for efficient display of long lists
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: dummyPosts.length,
        itemBuilder: (context, index) {
          final post = dummyPosts[index];
          return PostCard(post: post);
        },
      ),

      // Floating Action Button for creating a new post (assuming CreatePostPage is available)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the Create Post screen
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
        },
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Post'),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}


