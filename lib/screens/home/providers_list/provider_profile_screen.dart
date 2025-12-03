import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/screens/auth/constants.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderProfileScreen extends StatelessWidget {
  final ProviderModel provider;

  const ProviderProfileScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kPrimaryBlue.withOpacity(0.8),
                      kPrimaryBlue.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _showImageDialog(
                                context,
                                provider.photoUrl,
                                "Profile Photo",
                              );
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: provider.photoUrl.isNotEmpty
                                        ? Image.network(
                                            provider.photoUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(Icons.person_rounded,
                                                size: 40,
                                                color: Colors.grey.shade400),
                                          ),
                                  ),
                                  if (provider.photoUrl.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: kPrimaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.link,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: kDarkTextColor,
                                    fontFamily: 'Exo2',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  provider.profession,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: kPrimaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Exo2',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 16, color: kMutedTextColor),
                                    SizedBox(width: 4),
                                    Text(
                                      '${provider.commune}, ${provider.wilaya}',
                                      style: TextStyle(
                                        color: kMutedTextColor,
                                        fontFamily: 'Exo2',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (provider.subscriptionActive)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.green.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Exo2',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                provider.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                              Text(
                                'Rating',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.amber.shade300,
                          ),
                          Column(
                            children: [
                              Text(
                                '${provider.serviceIds.length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryBlue,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                              Text(
                                'Services',
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.amber.shade300,
                          ),
                          Column(
                            children: [
                              Text(
                                '${provider.serviceImages.length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green.shade700,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                              Text(
                                'Photos',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (provider.serviceImages.isNotEmpty)
                      _buildSection(
                        title: 'Service Photos',
                        icon: Icons.photo_library_rounded,
                        child: _buildServicePhotos(provider),
                      ),
                    if (provider.serviceImages.isNotEmpty) SizedBox(height: 24),
                    _buildSection(
                      title: 'About',
                      icon: Icons.info_rounded,
                      child: Text(
                        provider.description.isNotEmpty
                            ? provider.description
                            : 'No description provided.',
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontFamily: 'Exo2',
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildSection(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_rounded,
                      child: _buildContactInfo(provider, context),
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _openChat(context, provider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.message_rounded),
                            label: Text(
                              'Message',
                              style: TextStyle(
                                fontFamily: 'Exo2',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final url = Uri.parse('tel:${provider.phone}');
                              launchUrl(url);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.phone_rounded),
                            label: Text(
                              'Call',
                              style: TextStyle(
                                fontFamily: 'Exo2',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              String phoneNumber = provider.whatsapp.isNotEmpty
                                  ? provider.whatsapp
                                  : provider.phone;
                              final cleanedPhone =
                                  phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
                              final url =
                                  Uri.parse('https://wa.me/$cleanedPhone');
                              launchUrl(url);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(CupertinoIcons.phone),
                            label: Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontFamily: 'Exo2',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePhotos(ProviderModel provider) {
    List<String> images = provider.serviceImages;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _showImageDialog(
              context,
              images[index],
              "Service Photo ${index + 1}",
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.photo,
                      color: Colors.grey.shade400,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Exo2',
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.white, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Exo2',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      imageUrl,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await launchUrl(Uri.parse(imageUrl));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to open URL'),
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to open chat (FIXED VERSION)
  void _openChat(BuildContext context, ProviderModel provider) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showLoginDialog(context);
        return;
      }

      final currentUserId = currentUser.uid;
      final providerId = provider.uid!;
      final providerName = provider.name;
      final providerPhotoUrl = provider.photoUrl;

      if (currentUserId == providerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You cannot chat with yourself'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final chatViewModel = ChatViewModel(userId: currentUserId);
      final canonicalChatId = getCanonicalChatId(currentUserId, providerId);
      final existingChat = await chatViewModel.getChatById(canonicalChatId);

      String chatId;

      if (existingChat != null) {
        chatId = canonicalChatId;
      } else {
        final newChatId = await chatViewModel.createChat(
          clientId: currentUserId,
          providerId: providerId,
        );

        if (newChatId == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create chat'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        chatId = newChatId;
      }

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiscussionPage(
            contactName: providerName,
            isOnline: true,
            chatId: chatId,
            currentUserId: currentUserId,
            chatViewModel: chatViewModel,
            profileImageUrl: providerPhotoUrl,
            contactUserId: providerId,
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error opening chat: $e');
    }
  }

  String getCanonicalChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text('You need to login to send messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kDarkTextColor,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildContactInfo(ProviderModel provider, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (provider.phone.isNotEmpty)
            _buildContactItem(
              icon: Icons.phone_rounded,
              iconColor: kPrimaryBlue,
              title: 'Phone',
              value: provider.phone,
              onTap: () {
                final url = Uri.parse('tel:${provider.phone}');
                launchUrl(url);
              },
            ),
          if (provider.whatsapp.isNotEmpty)
            _buildContactItem(
              icon: Icons.phone,
              iconColor: Colors.green,
              title: 'WhatsApp',
              value: provider.whatsapp,
              onTap: () {
                final cleanedPhone =
                    provider.whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
                final url = Uri.parse('https://wa.me/$cleanedPhone');
                launchUrl(url);
              },
            ),
          _buildContactItem(
            icon: Icons.location_on_rounded,
            iconColor: Colors.orange,
            title: 'Address',
            value: provider.address,
            onTap: () {
              // Could open maps here
            },
          ),
          if (provider.photoUrl.isNotEmpty)
            _buildContactItem(
              icon: Icons.person_rounded,
              iconColor: Colors.purple,
              title: 'Profile Photo',
              value: provider.photoUrl,
              onTap: () {
                _showImageDialog(
                  context,
                  provider.photoUrl,
                  "Profile Photo",
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: kMutedTextColor,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kDarkTextColor,
                      fontFamily: 'Exo2',
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
