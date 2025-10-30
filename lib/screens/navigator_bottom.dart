import 'package:flutter/material.dart';
import 'package:myapp/screens/chat/chat_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/screens/profile/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/search/search_screen.dart';
import 'package:myapp/screens/posts/posts_screen.dart';

class NavigatorBottom extends StatefulWidget {
  const NavigatorBottom({super.key}); // 👈 constructor with super.key

  @override
  State<NavigatorBottom> createState() => _NavigatorBottomState();
}

class _NavigatorBottomState extends State<NavigatorBottom> {
  int selectorIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    MapSearchPage(),
    PostScreen(),
    ChatPage(),
    ProfilePage(),
  ];

  final Color highlight = const Color.fromARGB(255, 28, 130, 213);

  Widget _buildIcon(
    int index,
    IconData outline,
    IconData filled,
    Color highlight,
  ) {
    bool selected;
    if (selectorIndex == index) {
      selected = true;
    } else {
      selected = false;
    }

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
    return Scaffold(
      body: _pages[selectorIndex],
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
              /*  switch (val) {
                case 0:
                  print("services");
                  break;
                case 1:
                  print("search");
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                  break;
                case 3:
                  print("chat");
                  break;
                case 4:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                  break;
                default:
                  break;
              } */
            },
          ),
        ),
      ),
    );
  }
}
