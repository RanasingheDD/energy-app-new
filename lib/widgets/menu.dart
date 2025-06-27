import 'package:flutter/material.dart';
import 'package:myapp/data/menu_data.dart';

class SideMenuWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onMenuSelect;

  const SideMenuWidget({
    super.key,
    required this.currentIndex,
    required this.onMenuSelect,
  });

  @override
  Widget build(BuildContext context) {
    final menuData = SideMenuData();
    const backgroundColor = Color.fromARGB(255, 21, 17, 37); 
    const textColor = Colors.white;

    return Drawer(
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            const DrawerHeader(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Main Menu',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: menuData.menu.length,
                itemBuilder: (context, index) {
                  final item = menuData.menu[index];
                  final isSelected = index == currentIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurpleAccent.shade200 : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : textColor,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        onMenuSelect(index);
                        Navigator.pop(context); // Closes Drawer
                        Future.delayed(const Duration(milliseconds: 200), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.page),
                          );
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
