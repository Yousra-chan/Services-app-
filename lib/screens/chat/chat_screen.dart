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
          return _buildChatScreen(chatViewModel);
        },
      ),
    );
  }

  Widget _buildChatScreen(ChatViewModel chatViewModel) {
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
                            buildAvatar(false, contact['imageUrl']!),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data ?? [];

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
                        Text(
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
                    final contactName =
                        chat.getOtherParticipantName(widget.userId);

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
      final otherUserId =
          chat.clientId == currentUserId ? chat.providerId : chat.clientId;
      final contactName = chat.getOtherParticipantName(currentUserId);

      if (!contacts.containsKey(otherUserId)) {
        contacts[otherUserId] = {
          'id': otherUserId,
          'name': contactName,
          'imageUrl': '', // You can add profile image URL here if available
        };
      }
    }

    return contacts.values.toList();
  }

  void _showProviderSelection(
      BuildContext context, ChatViewModel chatViewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: chatViewModel.getAvailableProviders(),
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 400,
              child: Column(
                children: [
                  Text(
                    'Choisir un prestataire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : snapshot.hasError
                            ? const Center(child: Text('Erreur de chargement'))
                            : snapshot.data!.isEmpty
                                ? const Center(
                                    child: Text('Aucun prestataire disponible'))
                                : ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final provider = snapshot.data![index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: kLightGreyBlue,
                                          child: Icon(
                                              CupertinoIcons.person_fill,
                                              color: kPrimaryBlue),
                                        ),
                                        title: Text(provider['name']),
                                        subtitle: Text(provider['email']),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _createNewChatWithProvider(context,
                                              chatViewModel, provider['id']);
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
      },
    );
  }

  void _createNewChat(BuildContext context, ChatViewModel chatViewModel) {
    _showProviderSelection(context, chatViewModel);
  }

  void _createNewChatWithProvider(
      BuildContext context, ChatViewModel chatViewModel, String providerId) {
    chatViewModel
        .createChat(
      clientId: widget.userId,
      providerId: providerId,
    )
        .then((chatId) {
      if (chatId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discussion créée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}
