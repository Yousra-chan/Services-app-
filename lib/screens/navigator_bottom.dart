import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/chat/chat_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_page_loader.dart';
import 'package:myapp/screens/search/search_screen.dart';
import 'package:myapp/screens/posts/posts_screen.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';

class NavigatorBottom extends StatefulWidget {
  const NavigatorBottom({super.key});

  @override
  State<NavigatorBottom> createState() => _NavigatorBottomState();
}

class _NavigatorBottomState extends State<NavigatorBottom> {
  int selectorIndex = 0;

  final Color highlight = const Color.fromARGB(255, 28, 130, 213);

  Widget _buildIcon(
    int index,
    IconData outline,
    IconData filled,
    Color highlight,
  ) {
    final bool selected = selectorIndex == index;

    Icon icon;
    if (selected) {
      icon = Icon(filled, size: 28, color: highlight);
    } else {
      icon = Icon(outline, size: 24, color: Color.fromARGB(255, 7, 66, 115));
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (selected)
            BoxShadow(
              color: highlight.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Vérifier si l'utilisateur est connecté
    if (authViewModel.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Chargement du profil utilisateur...'),
            ],
          ),
        ),
      );
    }

    final String userId = authViewModel.currentUser!.uid;

    return Scaffold(
      body: IndexedStack(
        index: selectorIndex,
        children: [
          const HomePage(),
          const MapSearchPage(),
          const PostScreen(),
          ChatPage(userId: userId),
          const ProfilePageLoader(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 4, 32, 54),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 150, 150, 150),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            selectedItemColor: Color.fromARGB(255, 28, 130, 213),
            unselectedItemColor: Color.fromARGB(255, 7, 66, 115),
            selectedFontSize: 15,
            currentIndex: selectorIndex,
            items: [
              BottomNavigationBarItem(
                icon: _buildIcon(
                  0,
                  CupertinoIcons.briefcase,
                  CupertinoIcons.briefcase_fill,
                  highlight,
                ),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                  1,
                  CupertinoIcons.map,
                  CupertinoIcons.map,
                  highlight,
                ),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                  2,
                  CupertinoIcons.home,
                  CupertinoIcons.home,
                  highlight,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                  3,
                  CupertinoIcons.chat_bubble,
                  CupertinoIcons.chat_bubble_2_fill,
                  highlight,
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                  4,
                  CupertinoIcons.person,
                  CupertinoIcons.person_fill,
                  highlight,
                ),
                label: 'Profile',
              ),
            ],
            onTap: (val) {
              setState(() {
                selectorIndex = val;
              });
            },
          ),
        ),
      ),
    );
  }
}
