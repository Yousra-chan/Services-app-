import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:provider/provider.dart';
import 'posts_constants.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  String _formatTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inHours < 24) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    }
    return '${difference.inDays}d';
  }

  Future<void> _handleChatPress(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    final String peerId = post.userId;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to contact a user.'),
          backgroundColor: kSeekingColor,
        ),
      );
      return;
    }

    if (currentUser.uid == peerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You cannot chat with yourself.'),
          backgroundColor: kAccentColor,
        ),
      );
      return;
    }

    try {
      final chatViewModel = ChatViewModel(userId: currentUser.uid);
      final chatId = await chatViewModel.createChat(
        clientId: currentUser.uid,
        providerId: peerId,
      );

      if (chatId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionPage(
              chatId: chatId,
              currentUserId: currentUser.uid,
              contactName: post.user,
              isOnline: true,
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
            backgroundColor: kSeekingColor,
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
        post.type == PostType.seeking ? 'Looking for' : 'Offering';
    final IconData typeIcon = post.type == PostType.seeking
        ? CupertinoIcons.search
        : CupertinoIcons.briefcase;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - User info and time
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor.withOpacity(0.1),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      post.user.isNotEmpty ? post.user[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // User name and service type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user,
                        style: const TextStyle(
                          color: kDarkTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Exo2',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            typeIcon,
                            color: typeColor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Exo2',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: kMutedTextColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    ],
                  ),
                ),

                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kLightBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kMutedTextColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    post.serviceCategory,
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    color: kDarkTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Exo2',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  post.body,
                  style: const TextStyle(
                    color: kDarkTextColor,
                    fontSize: 14,
                    fontFamily: 'Exo2',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Action buttons
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.shade100,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Contact button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleChatPress(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_text,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Contact',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Exo2',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the rest of your CreatePostModal class as is...
class CreatePostModal extends StatefulWidget {
  final Function(Post post) onPostCreated;
  final UserModel user;

  const CreatePostModal({
    super.key,
    required this.onPostCreated,
    required this.user,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _body = '';

  PostType get _defaultType {
    return widget.user.isProvider ? PostType.offering : PostType.seeking;
  }

  PostType _type = PostType.seeking;
  String _serviceCategory = 'Electrician';

  final List<String> categories = [
    "Electrician",
    "Plumbing",
    "Tutoring",
    "Handyman",
    "Cleaning",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _type = _defaultType;
  }

  void _submitPost() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

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

      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        body: _body,
        user: widget.user.name,
        userId: widget.user.uid,
        type: _type,
        serviceCategory: _serviceCategory,
        timestamp: DateTime.now(),
      );

      widget.onPostCreated(newPost);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor =
        _type == PostType.seeking ? kSeekingColor : kOfferingColor;
    final bool isProvider = widget.user.isProvider;

    return Container(
      padding: const EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 30),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create Post",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      isProvider ? "Service Provider" : "Client",
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isProvider
                    ? "Share your professional services with the community"
                    : "Let providers know what service you need",
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 30, color: Color(0xFFE5E5E5)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isProvider
                          ? CupertinoIcons.hand_raised
                          : CupertinoIcons.heart,
                      color: typeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isProvider ? "I Offer Service" : "I Need Service",
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                decoration: _inputDecoration(isProvider
                    ? "Service Title (e.g., Professional Electrical Services)"
                    : "What do you need? (e.g., Need Electrician for Home Wiring)"),
                maxLength: 60,
                validator: (value) =>
                    value!.isEmpty ? 'Title cannot be empty' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: _inputDecoration(isProvider
                    ? "Describe your service, experience, and expertise..."
                    : "Describe your needs, location, and any specific requirements..."),
                maxLines: 4,
                maxLength: 300,
                validator: (value) =>
                    value!.length < 10 ? 'Description is too short' : null,
                onSaved: (value) => _body = value!,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kCardBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kMutedTextColor.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _serviceCategory,
                    isExpanded: true,
                    icon:
                        Icon(CupertinoIcons.chevron_down, color: kPrimaryBlue),
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
              ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Publish Post",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
