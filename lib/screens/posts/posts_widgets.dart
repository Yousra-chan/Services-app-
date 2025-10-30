import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'posts_constants.dart';



class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  // Helper to format the timestamp (e.g., "3h ago", "1d ago")
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

  @override
  Widget build(BuildContext context) {
    // Determine color and text based on post type
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
          // Header: User, Type Badge, and Time
          Row(
            children: [
              // User/Avatar Placeholder
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.2),
                radius: 18,
                child: Text(
                  post.user[0],
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // User Name
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

              // Type Badge (I Need / I Offer)
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

              // Timestamp
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

          // Title
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

          // Body/Description
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

          // Footer: Category and Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Chip
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

              // Action Button
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Contacting ${post.user} for ${post.serviceCategory}...",
                        style: const TextStyle(fontFamily: 'Exo2'),
                      ),
                    ),
                  );
                },
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

// --- Create Post Modal Widget ---

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
  PostType _type = PostType.seeking; // Default to seeking
  String _serviceCategory = 'Electrician'; // Default

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

      // Create a mock post object
      final newPost = Post(
        title: _title,
        body: _body,
        user: "Current User", // Placeholder user name
        type: _type,
        serviceCategory: _serviceCategory,
        timestamp: DateTime.now(),
      );

      widget.onPostCreated(newPost);
      // Close the modal
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically change color based on selected post type
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
                  children:
                      PostType.values.map((type) {
                        bool isSelected = _type == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _type = type;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? typeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                type == PostType.seeking
                                    ? "I Need Service"
                                    : "I Offer Service",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : kDarkTextColor,
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
                  'Title (e.g., Need Electrician in North District)',
                ),
                maxLength: 50,
                validator:
                    (value) => value!.isEmpty ? 'Title cannot be empty' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 10),

              // Body Input
              TextFormField(
                decoration: _inputDecoration(
                  'Describe your needs or service offered...',
                ),
                maxLines: 4,
                maxLength: 200,
                validator:
                    (value) =>
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
                    icon: const Icon(
                      CupertinoIcons.chevron_down,
                      color: kPrimaryBlue,
                    ),
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 16,
                      fontFamily: 'Exo2',
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _serviceCategory = newValue;
                        });
                      }
                    },
                    items:
                        categories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
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

  // Consistent Input Decoration style
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
