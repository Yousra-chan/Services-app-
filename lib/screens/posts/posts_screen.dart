import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// Note: Assuming Post, dummyPosts are here.
import 'posts_constants.dart';
// Note: Assuming PostCard is here.
import 'posts_widgets.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  // The state holds the list of posts, initialized with dummy data
  final List<Post> _posts = dummyPosts;

  void _openCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          // Adjust bottom padding to accommodate the keyboard, preventing overflow
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // Assuming CreatePostModal is the name of your modal widget
          child: CreatePostModal(onPostCreated: _addNewPost),
        );
      },
    );
  }

  void _addNewPost(Post newPost) {
    // Add the new post to the beginning of the list (most recent first)
    setState(() {
      _posts.insert(0, newPost);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Post published successfully!",
          style: TextStyle(fontFamily: 'Exo2'),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardBackgroundColor,
        elevation: 1, // Subtle shadow for header separation
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: kDarkTextColor),
          onPressed: () {
            // Placeholder for back functionality
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Community Board',
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            fontFamily: 'Exo2',
          ),
        ),
      ),

      body:
          _posts.isEmpty
              ? const Center(
                child: Text(
                  "No posts yet. Be the first!",
                  style: TextStyle(
                    color: kMutedTextColor,
                    fontSize: 18,
                    fontFamily: 'Exo2',
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: _posts[index]);
                },
              ),

      // Floating Action Button to create a new post
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostModal, // 👈 Using the local modal function
        backgroundColor: kPrimaryBlue,
        label: const Row(
          children: [
            Icon(
              CupertinoIcons.plus_circle_fill,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              "New Post",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
