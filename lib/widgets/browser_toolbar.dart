import 'package:flutter/material.dart';

/// Bottom navigation bar: back, forward, home, reload/stop, tabs.
class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({
    super.key,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onHome,
    required this.isLoading,
    required this.tabCount,
    required this.onTabsPressed,
  });

  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onHome;
  final bool isLoading;
  final int tabCount;
  final VoidCallback onTabsPressed;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: onBack,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Forward',
            onPressed: onForward,
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: onHome,
          ),
          IconButton(
            icon: Icon(isLoading ? Icons.close : Icons.refresh),
            tooltip: isLoading ? 'Stop' : 'Reload',
            onPressed: onReload,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_none),
                tooltip: 'Tabs',
                onPressed: onTabsPressed,
              ),
              if (tabCount > 1)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$tabCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: Colors.white),
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
