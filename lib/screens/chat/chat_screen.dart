import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/models/ChatModel.dart';
import 'package:myapp/screens/chat/constants.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:intl/intl.dart';

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
      child: isSearchIcon
          ? Icon(CupertinoIcons.search, color: kPrimaryBlue, size: 26)
          : (imageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(CupertinoIcons.person_fill,
                  color: kPrimaryBlue, size: 26)),
    ),
  );
}

Widget buildChatTile(
  BuildContext context,
  ChatModel chat,
  String userId, {
  required int unreadCount,
  required String contactName,
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
          CircleAvatar(
            radius: 28,
            backgroundColor: kLightGreyBlue,
            child: Icon(
              CupertinoIcons.person_fill,
              color: kPrimaryBlue,
              size: 30,
            ),
          ),
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
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - you could reset badge here if needed
      // For example, you could mark all messages as read when app comes to foreground
      // and the chat screen is visible
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatViewModel(userId: widget.userId),
      child: Consumer<ChatViewModel>(
        builder: (context, chatViewModel, child) {
          return _buildChatScreen(context, chatViewModel); // Added context
        },
      ),
    );
  }

  Widget _buildChatScreen(BuildContext context, ChatViewModel chatViewModel) {
    return Scaffold(
      backgroundColor: kLightGreyBlue,
      appBar: AppBar(
        title: const Text(
          "Discussions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        elevation: 0,
        backgroundColor: kPrimaryBlue,
      ),
      body: Column(
        children: [
          // Section Stories/Status - Now shows only previous contacts
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: StreamBuilder<List<ChatModel>>(
              stream: chatViewModel.userChatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final chats = snapshot.data ?? [];

                // Extract unique contacts from chats
                final contacts =
                    _extractContactsFromChats(chats, widget.userId);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contacts.length + 1, // +1 for search icon
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    // Look for this existing code and replace the entire itemBuilder:
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Search icon
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              buildAvatar(true),
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Rechercher",
                                  style: TextStyle(
                                    color: Colors.white70,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildAvatar(
                                false,
                                contact[
                                    'imageUrl']!), // ← This is the problematic line
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: SizedBox(
                                width: 60,
                                child: Text(
                                  contact['name']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
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
            ),
          ),
          const SizedBox(height: 15),

          // Liste des discussions
          // In chat_screen.dart - Fix the chat list builder
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: chatViewModel.userChatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
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
                          color: kMutedTextColor,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucune discussion',
                          style: TextStyle(
                            color: kMutedTextColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () =>
                              _createNewChat(context, chatViewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Commencer une discussion'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    // Safe way to get contact name
                    String contactName;
                    try {
                      contactName = chat.getOtherParticipantName(widget.userId);
                    } catch (e) {
                      print('❌ Error getting participant name: $e');
                      contactName = 'Unknown User';
                    }

                    return AnimatedChatListItem(
                      index: index,
                      child: StreamBuilder<int>(
                        stream: chatViewModel.getUnreadCount(chat.chatId),
                        builder: (context, unreadSnapshot) {
                          final unreadCount = unreadSnapshot.data ?? 0;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DiscussionPage(
                                    contactName: contactName,
                                    isOnline: true,
                                    chatId: chat.chatId,
                                    currentUserId: widget.userId,
                                    chatViewModel: chatViewModel,
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProviderSelection(context, chatViewModel),
        backgroundColor: kPrimaryBlue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  // Extract unique contacts from chats

  List<Map<String, String>> _extractContactsFromChats(
      List<ChatModel> chats, String currentUserId) {
    final contacts = <String, Map<String, String>>{};

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipantId(currentUserId);
        final contactName = chat.getOtherParticipantName(currentUserId);

        // Get profile image URL from participantNames or use default
        final imageUrl = chat.participantNames[otherUserId] != null
            ? '' // You can add actual image URL logic here if available
            : '';

        if (!contacts.containsKey(otherUserId)) {
          contacts[otherUserId] = {
            'id': otherUserId,
            'name': contactName,
            'imageUrl': imageUrl,
          };
        }
      } catch (e) {
        print('❌ Error extracting contact from chat ${chat.chatId}: $e');
        // Continue with next chat instead of breaking
        continue;
      }
    }

    return contacts.values.toList();
  }

// In chat_screen.dart - Fix the _showProviderSelection method
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
                                // Option to invite providers or show help
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kPrimaryBlue,
                              child: provider['photoUrl']?.isNotEmpty == true
                                  ? ClipOval(
                                      child: Image.network(
                                        provider['photoUrl']!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      provider['name']![0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                            ),
                            title: Text(
                              provider['name'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(provider['email'] ?? ''),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context);
                              _createNewChatWithProvider(
                                  context,
                                  chatViewModel,
                                  provider['id']!,
                                  provider['name'] ?? 'Prestataire');
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
