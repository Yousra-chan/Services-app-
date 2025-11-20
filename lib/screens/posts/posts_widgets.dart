import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart'; // REQUIRED
import 'posts_constants.dart';

// --- NEW IMPORTS REQUIRED FOR CHAT ---
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
// Note: You may need to import your 'Post' model definition if it's not here.
// Note: You may need to import your 'ProviderModel' definition if your post stores the full provider object.

// --- POST CARD WIDGET ---
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  String _formatTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inHours < 24) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  // --- NEW HANDLER FUNCTION ---
  Future<void> _handleChatPress(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    final String peerId = post.userId;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to contact a user.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentUser.uid == peerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show temporary loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting chat...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 1. Initialize ChatViewModel
      final chatViewModel = ChatViewModel(userId: currentUser.uid);

      // 2. Get or Create the Chat ID
      final chatId = await chatViewModel.createChat(
        clientId: currentUser.uid,
        providerId: peerId,
      );

      if (chatId != null && context.mounted) {
        // 3. Navigate to Discussion Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionPage(
              chatId: chatId,
              currentUserId: currentUser.uid,
              contactName: post.user, // Use the post author's name
              isOnline: true, // Placeholder
              chatViewModel: chatViewModel,
            ),
          ),
        );
      } else if (context.mounted) {
        throw Exception("Failed to retrieve or create chat ID.");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not start chat. $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color typeColor =
        post.type == PostType.seeking ? kSeekingColor : kOfferingColor;
    final String typeLabel =
        post.type == PostType.seeking ? 'I Need' : 'I Offer';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row (Avatar, Name, Type, Time)
          Row(
            children: [
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.2),
                radius: 18,
                child: Text(
                  post.user.isNotEmpty ? post.user[0] : '?',
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.user,
                  style: const TextStyle(
                    color: kDarkTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatTime(post.timestamp),
                style: const TextStyle(
                  color: kMutedTextColor,
                  fontSize: 12,
                  fontFamily: 'Exo2',
                ),
              ),
            ],
          ),

          const Divider(
            height: 25,
            thickness: 0.5,
            color: kLightBackgroundColor,
          ),

          // Post Title and Body
          Text(
            post.title,
            style: const TextStyle(
              color: kDarkTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 14,
              fontFamily: 'Exo2',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),

          // Category and Contact Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kLightBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withOpacity(0.5)),
                ),
                child: Text(
                  post.serviceCategory,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),

              // Contact Button (UPDATED HERE)
              TextButton.icon(
                onPressed: () =>
                    _handleChatPress(context), // Calling the new handler
                icon: const Icon(
                  CupertinoIcons.chat_bubble_2,
                  color: kPrimaryBlue,
                  size: 20,
                ),
                label: const Text(
                  'Contact',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- CREATE POST MODAL WIDGET ---

class CreatePostModal extends StatefulWidget {
  final Function(Post post) onPostCreated;

  const CreatePostModal({super.key, required this.onPostCreated});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _body = '';
  PostType _type = PostType.seeking;
  String _serviceCategory = 'Electrician';

  final List<String> categories = [
    "Electrician",
    "Plumbing",
    "Tutoring",
    "Handyman",
    "Other",
  ];

  void _submitPost() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Get current user data using Provider
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: You must be logged in to create a post.'),
            backgroundColor: kSeekingColor,
          ),
        );
        return;
      }

      // Determine the user's display name, using email as a fallback
      // We assume UserModel has both 'name' (for display) and 'email'
      final String userName = currentUser.name ??
          currentUser.email ??
          'Anonymous User'; // <-- FIX: Use email as a better fallback

      // Create the new post object
      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        body: _body,

        // Use the determined user name
        user: userName,

        userId: currentUser.uid,
        type: _type,
        serviceCategory: _serviceCategory,
        timestamp: DateTime.now(),
      );

      // Pass the data back to the parent (FeedScreen)
      widget.onPostCreated(newPost);

      // Close the modal
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor =
        _type == PostType.seeking ? kSeekingColor : kOfferingColor;

    return Container(
      padding: const EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 25),
      decoration: const BoxDecoration(
        color: kLightBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create a New Post",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Exo2',
                ),
              ),
              const Divider(height: 30, color: kMutedTextColor),

              // Post Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: kCardBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: PostType.values.map((type) {
                    bool isSelected = _type == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? typeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            type == PostType.seeking
                                ? "I Need Service"
                                : "I Offer Service",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : kDarkTextColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Exo2',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Title Input
              TextFormField(
                decoration: _inputDecoration(
                    'Title (e.g., Need Electrician in North District)'),
                maxLength: 50,
                validator: (value) =>
                    value!.isEmpty ? 'Title cannot be empty' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 10),

              // Body Input
              TextFormField(
                decoration: _inputDecoration(
                    'Describe your needs or service offered...'),
                maxLines: 4,
                maxLength: 200,
                validator: (value) =>
                    value!.length < 10 ? 'Description is too short' : null,
                onSaved: (value) => _body = value!,
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: kCardBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kMutedTextColor.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _serviceCategory,
                    isExpanded: true,
                    icon: const Icon(CupertinoIcons.chevron_down,
                        color: kPrimaryBlue),
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 16,
                      fontFamily: 'Exo2',
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _serviceCategory = newValue);
                      }
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Publish Post",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kMutedTextColor, fontFamily: 'Exo2'),
      floatingLabelStyle: const TextStyle(
        color: kPrimaryBlue,
        fontWeight: FontWeight.bold,
        fontFamily: 'Exo2',
      ),
      filled: true,
      fillColor: kCardBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }
}
