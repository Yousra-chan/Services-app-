import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' hide Widget;
import 'package:http/http.dart' as http;
import 'package:myapp/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/models/ChatModel.dart';
import 'package:myapp/screens/chat/constants.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart'
    hide Widget;
import 'package:intl/intl.dart';

// Add the missing buildAvatar function
Widget buildAvatar(bool isSearchIcon, [String imageUrl = '']) {
  return Container(
    width: 55,
    height: 55,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: isSearchIcon ? Colors.transparent : Colors.white54,
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(isSearchIcon ? 0.0 : 0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CircleAvatar(
      radius: 25,
      backgroundColor: isSearchIcon ? Colors.white : kLightGreyBlue,
      backgroundImage: !isSearchIcon && imageUrl.isNotEmpty
          ? ImageUtils.getImageProvider(imageUrl)
          : null,
      child: isSearchIcon
          ? Icon(CupertinoIcons.search, color: kPrimaryBlue, size: 26)
          : (imageUrl.isEmpty
              ? Icon(CupertinoIcons.person_fill, color: kPrimaryBlue, size: 26)
              : _buildImageLoadingFallback(imageUrl)),
    ),
  );
}

Widget _buildImageLoadingFallback(String imageUrl) {
  return FutureBuilder<bool>(
    future: _checkImageValidity(imageUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
        );
      }

      if (snapshot.hasError || !(snapshot.data ?? false)) {
        return Icon(CupertinoIcons.person_fill, color: kPrimaryBlue, size: 26);
      }

      return Container();
    },
  );
}

Future<bool> _checkImageValidity(String imageUrl) async {
  try {
    if (ImageUtils.isNetworkImage(imageUrl)) {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } else if (ImageUtils.isBase64Image(imageUrl)) {
      final bytes = ImageUtils.decodeBase64Image(imageUrl);
      return bytes != null && bytes.isNotEmpty;
    }
    return false;
  } catch (e) {
    return false;
  }
}

Widget buildChatTile(
  BuildContext context,
  ChatModel chat,
  String userId, {
  required int unreadCount,
  required String contactName,
  String? profileImageUrl,
}) {
  final bool isUnread = unreadCount > 0;
  final bool isOnline = chat.providerId.hashCode % 3 == 0;

  final String lastMessageText =
      chat.lastMessage.isEmpty ? "Démarrer la discussion..." : chat.lastMessage;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Enhanced avatar with base64 support
          _buildEnhancedChatAvatar(profileImageUrl ?? ''),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent[400],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        contactName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
          color: kPrimaryBlue,
          fontFamily: 'Exo2',
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          lastMessageText,
          style: TextStyle(
            fontSize: 13,
            color: isUnread ? kPrimaryBlue.withOpacity(0.8) : Colors.grey[600],
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Exo2',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTimestamp(chat.lastMessageTime.toDate()),
            style: TextStyle(
              fontSize: 11,
              color: isUnread ? kPrimaryBlue : Colors.grey[500],
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 6),
          if (isUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: kPrimaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? "99+" : "$unreadCount",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildEnhancedChatAvatar(String imageUrl) {
  // If imageUrl is empty, show placeholder immediately
  if (imageUrl.isEmpty) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white54,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kSoftShadowColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: kLightGreyBlue,
        child: Icon(
          CupertinoIcons.person_fill,
          color: kPrimaryBlue,
          size: 26,
        ),
      ),
    );
  }

  final imageProvider = ImageUtils.getImageProvider(imageUrl);

  return Container(
    width: 55,
    height: 55,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white54,
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CircleAvatar(
      radius: 25,
      backgroundColor: kLightGreyBlue,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(
              CupertinoIcons.person_fill,
              color: kPrimaryBlue,
              size: 26,
            )
          : _buildChatAvatarLoadingFallback(imageUrl),
    ),
  );
}

Widget _buildChatAvatarLoadingFallback(String imageUrl) {
  return FutureBuilder<bool>(
    future: _checkImageValidity(imageUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
        );
      }

      if (snapshot.hasError || !(snapshot.data ?? false)) {
        return Icon(
          CupertinoIcons.person_fill,
          color: kPrimaryBlue,
          size: 26,
        );
      }

      return Container();
    },
  );
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays == 0) {
    return DateFormat('HH:mm').format(timestamp);
  } else if (difference.inDays == 1) {
    return "Hier";
  } else if (difference.inDays < 7) {
    return DateFormat('EEEE').format(timestamp);
  } else {
    return DateFormat('dd/MM/yy').format(timestamp);
  }
}

class AnimatedChatListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const AnimatedChatListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ChatPage extends StatefulWidget {
  final String userId;

  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _createNewChatWithProvider(BuildContext context,
      ChatViewModel chatViewModel, String providerId, String providerName) {
    // Get current user ID
    final currentUserId = widget.userId;

    // Prevent self-chatting
    if (currentUserId == providerId) {
      _showErrorDialog(context, 'Action non autorisée',
          'Vous ne pouvez pas créer une discussion avec vous-même.');
      return;
    }

    print('💬 Creating chat with provider: $providerId ($providerName)');

    // Store context in a variable before async operation
    final scaffoldContext = context;

    chatViewModel
        .createChat(
      clientId: currentUserId,
      providerId: providerId,
    )
        .then((chatId) {
      if (chatId != null) {
        print('✅ Chat created successfully: $chatId');

        // Use the stored context with a mounted check
        if (scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Discussion créée avec $providerName!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Close the provider selection modal
          Navigator.pop(scaffoldContext);
        }

        // Refresh the chat list
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ Failed to create chat');
        if (scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création de la discussion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }).catchError((error) {
      print('❌ Error creating chat: $error');
      if (scaffoldContext.mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Helper method to show error dialog
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatViewModel(userId: widget.userId),
      child: Consumer<ChatViewModel>(
        builder: (context, chatViewModel, child) {
          return _buildChatScreen(context, chatViewModel);
        },
      ),
    );
  }

  Widget _buildChatScreen(BuildContext context, ChatViewModel chatViewModel) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 12, 94, 153), // kPrimaryBlue
              Color(0xFF4A6FDC),
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: Column(
          children: [
            // Enhanced Gradient Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 25,
                right: 25,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Discussions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Exo2',
                        ),
                      ),
                      // You can add notification icon or other widgets here
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Main Content Area with subtle gradient continuation
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // Stories Section with gradient background
                    Container(
                      height: 110,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: StreamBuilder<List<ChatModel>>(
                        stream: chatViewModel.userChatsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          }

                          final chats = snapshot.data ?? [];
                          return FutureBuilder<List<Map<String, String>>>(
                            future: _extractContactsFromChats(
                                chats, widget.userId, chatViewModel),
                            builder: (context, contactsSnapshot) {
                              if (contactsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                );
                              }

                              final contacts = contactsSnapshot.data ?? [];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: contacts.length + 1,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      // Search icon using buildAvatar
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            buildAvatar(true), // Search avatar
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                "Rechercher",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontFamily: 'Exo2',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final contact = contacts[index - 1];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Use buildAvatar for contact avatars
                                          buildAvatar(
                                              false, contact['imageUrl'] ?? ''),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: SizedBox(
                                              width: 60,
                                              child: Text(
                                                contact['name']!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontFamily: 'Exo2',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Chat List
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: StreamBuilder<List<ChatModel>>(
                          stream: chatViewModel.userChatsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      kPrimaryBlue),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              print('Chat list error: ${snapshot.error}');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 50),
                                    const SizedBox(height: 10),
                                    Text('Erreur: ${snapshot.error}'),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => setState(() {}),
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final chats = snapshot.data ?? [];
                            print('💬 Loaded ${chats.length} chats');

                            if (chats.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_outlined,
                                      color: kPrimaryBlue,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Aucune discussion',
                                      style: TextStyle(
                                        color: kPrimaryBlue,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => _createNewChat(
                                          context, chatViewModel),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryBlue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                          'Commencer une discussion'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return FutureBuilder<Map<String, String>>(
                              future: _getChatProfileImages(
                                  chats, widget.userId, chatViewModel),
                              builder: (context, profileImagesSnapshot) {
                                if (profileImagesSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          kPrimaryBlue),
                                    ),
                                  );
                                }

                                final profileImages =
                                    profileImagesSnapshot.data ?? {};

                                return ListView.separated(
                                  itemCount: chats.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 2),
                                  itemBuilder: (context, index) {
                                    final chat = chats[index];
                                    String contactName;

                                    try {
                                      contactName =
                                          chat.getOtherParticipantName(
                                              widget.userId);
                                    } catch (e) {
                                      print(
                                          '❌ Error getting participant name: $e');
                                      contactName = 'Unknown User';
                                    }

                                    final otherUserId = chat
                                        .getOtherParticipantId(widget.userId);
                                    final profileImageUrl =
                                        profileImages[otherUserId] ?? '';

                                    return AnimatedChatListItem(
                                      index: index,
                                      child: StreamBuilder<int>(
                                        stream: chatViewModel
                                            .getUnreadCount(chat.chatId),
                                        builder: (context, unreadSnapshot) {
                                          final unreadCount =
                                              unreadSnapshot.data ?? 0;

                                          return InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DiscussionPage(
                                                    contactName: contactName,
                                                    isOnline: true,
                                                    chatId: chat.chatId,
                                                    currentUserId:
                                                        widget.userId,
                                                    chatViewModel:
                                                        chatViewModel,
                                                    profileImageUrl:
                                                        profileImageUrl,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: buildChatTile(
                                              context,
                                              chat,
                                              widget.userId,
                                              unreadCount: unreadCount,
                                              contactName: contactName,
                                              profileImageUrl: profileImageUrl,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProviderSelection(context, chatViewModel),
        backgroundColor: Colors.white,
        child: Icon(Icons.chat, color: kPrimaryBlue),
      ),
    );
  }

  // Extract unique contacts from chats with profile images
  Future<List<Map<String, String>>> _extractContactsFromChats(
      List<ChatModel> chats,
      String currentUserId,
      ChatViewModel chatViewModel) async {
    final contacts = <String, Map<String, String>>{};

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipantId(currentUserId);
        final contactName = chat.getOtherParticipantName(currentUserId);

        // Fetch actual profile image URL using the passed chatViewModel
        final imageUrl =
            await chatViewModel.getUserProfileImageUrl(otherUserId) ?? '';

        if (!contacts.containsKey(otherUserId)) {
          contacts[otherUserId] = {
            'id': otherUserId,
            'name': contactName,
            'imageUrl': imageUrl,
          };
        }
      } catch (e) {
        print('❌ Error extracting contact from chat ${chat.chatId}: $e');
        continue;
      }
    }

    return contacts.values.toList();
  }

  // Get profile images for all chats
  Future<Map<String, String>> _getChatProfileImages(List<ChatModel> chats,
      String currentUserId, ChatViewModel chatViewModel) async {
    final profileImages = <String, String>{};

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipantId(currentUserId);
        if (!profileImages.containsKey(otherUserId)) {
          final imageUrl =
              await chatViewModel.getUserProfileImageUrl(otherUserId) ?? '';
          profileImages[otherUserId] = imageUrl;
        }
      } catch (e) {
        print('❌ Error getting profile image for chat ${chat.chatId}: $e');
      }
    }

    return profileImages;
  }

  void _showProviderSelection(
      BuildContext context, ChatViewModel chatViewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choisir un prestataire',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: chatViewModel.getAvailableProviders(),
                  builder: (context, snapshot) {
                    print(
                        '🔍 Provider snapshot state: ${snapshot.connectionState}');
                    print('🔍 Provider snapshot has data: ${snapshot.hasData}');
                    print(
                        '🔍 Provider snapshot has error: ${snapshot.hasError}');

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Chargement des prestataires...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      print('❌ Error loading providers: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 50),
                            const SizedBox(height: 16),
                            const Text(
                              'Erreur de chargement',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showProviderSelection(context, chatViewModel);
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final providers = snapshot.data ?? [];
                    print('👥 Providers list length: ${providers.length}');

                    if (providers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun prestataire disponible',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Aucun prestataire n\'est inscrit sur la plateforme pour le moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _showNoProvidersHelp(context);
                              },
                              child: const Text('Que faire ?'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final String? photoUrl = provider['photoUrl'];
                        final String? name = provider['name'];

                        // Debug print to see what photo URLs we're getting
                        print(
                            '👤 Provider ${provider['name']} - Photo URL: "$photoUrl"');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: _buildProviderAvatar(photoUrl, name),
                            title: Text(
                              name ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(provider['email'] ?? ''),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context);
                              _createNewChatWithProvider(context, chatViewModel,
                                  provider['id']!, name ?? 'Prestataire');
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderAvatar(String? photoUrl, String? name) {
    // Debug print
    print('🖼️ Building provider avatar with URL: $photoUrl');

    // If no photo URL, show initial immediately
    if (photoUrl == null || photoUrl.isEmpty) {
      final String displayInitial =
          name != null && name.isNotEmpty ? name[0].toUpperCase() : '?';
      return CircleAvatar(
        radius: 24,
        backgroundColor: kPrimaryBlue,
        child: Text(
          displayInitial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    final imageProvider = ImageUtils.getImageProvider(photoUrl);
    final String displayInitial =
        name != null && name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: kPrimaryBlue,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              displayInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : _buildProviderAvatarLoadingFallback(photoUrl, displayInitial),
    );
  }

  Widget _buildProviderAvatarLoadingFallback(
      String photoUrl, String fallbackInitial) {
    return FutureBuilder<bool>(
      future: _checkImageValidity(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return Text(
            fallbackInitial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return Container();
      },
    );
  }

  void _showNoProvidersHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun prestataire disponible'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cela peut être dû à:'),
            SizedBox(height: 8),
            Text('• Aucun prestataire inscrit'),
            Text('• Problème de connexion'),
            Text('• Données non chargées'),
            SizedBox(height: 16),
            Text('Veuillez réessayer plus tard.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createNewChat(BuildContext context, ChatViewModel chatViewModel) {
    _showProviderSelection(context, chatViewModel);
  }
}
