import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/theme_service.dart';
import 'shared/services/item_service.dart';
import 'shared/services/deal_service.dart';
import 'shared/services/user_service.dart';
import 'shared/services/voice_assistant_service.dart';
import 'shared/widgets/voice_assistant_widget.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/deals/screens/deals_screen.dart';
import 'features/add_item/screens/add_item_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => ItemService()),
        ChangeNotifierProvider(create: (_) => DealService()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantService()),
      ],
      child: const ShelfTrackerApp(),
    ),
  );
}

class ShelfTrackerApp extends StatelessWidget {
  const ShelfTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'Shelf Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainNavigation(),
        '/add-item': (context) => const AddItemScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _showVoiceOverlay = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    DealsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    final userService = context.read<UserService>();
    final itemService = context.read<ItemService>();
    final dealService = context.read<DealService>();
    final voiceService = context.read<VoiceAssistantService>();

    await userService.initialize();
    await itemService.initialize();
    await dealService.initialize();
    await voiceService.initialize();
  }

  void _handleVoiceCommand(VoiceCommand command) {
    final voiceService = context.read<VoiceAssistantService>();
    final itemService = context.read<ItemService>();

    switch (command.type) {
      case 'add_item':
        voiceService.speak('Opening add item screen');
        Navigator.pushNamed(context, '/add-item', arguments: null);
        break;
      case 'add_item_voice':
        final itemName = command.data['name'] as String?;
        if (itemName != null && itemName.isNotEmpty) {
          voiceService.speak('Adding $itemName');
          Navigator.pushNamed(context, '/add-item', arguments: Map<String, dynamic>.from(command.data));
        } else if (command.data.isNotEmpty) {
          voiceService.speak('Opening add item screen');
          Navigator.pushNamed(context, '/add-item', arguments: Map<String, dynamic>.from(command.data));
        } else {
          voiceService.speak('Opening add item screen');
          Navigator.pushNamed(context, '/add-item', arguments: null);
        }
        break;
      case 'show_expiring':
        voiceService.speak('Showing items expiring soon');
        setState(() => _currentIndex = 0);
        break;
      case 'show_expired':
        voiceService.speak('Showing expired items');
        setState(() => _currentIndex = 0);
        break;
      case 'show_analytics':
        voiceService.speak('Showing analytics');
        setState(() => _currentIndex = 1);
        break;
      case 'show_deals':
        voiceService.speak('Showing deals');
        setState(() => _currentIndex = 2);
        break;
      case 'go_home':
        voiceService.speak('Going to home screen');
        setState(() => _currentIndex = 0);
        break;
      case 'show_profile':
        voiceService.speak('Showing your profile');
        setState(() => _currentIndex = 3);
        break;
      case 'search':
        final query = command.data['query'] as String?;
        if (query != null) {
          voiceService.speak('Searching for $query');
          itemService.searchItems(query);
          setState(() => _currentIndex = 0);
        }
        break;
      case 'help':
        voiceService.speak(
          'You can say: Add item, Show expiring, Show analytics, Show deals, Go home, Show profile, or Search followed by an item name.',
        );
        break;
      case 'no_speech':
        voiceService.speak("I didn't hear anything. Please tap the microphone and speak.");
        break;
      case 'timeout':
        voiceService.speak("Listening timed out. Please try again.");
        break;
      default:
        voiceService.speak("Sorry, I didn't understand that command. Say help for available commands.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer_rounded),
                label: 'Deals',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<VoiceAssistantService>(
                builder: (context, voiceService, child) {
                  return FloatingActionButton.small(
                    heroTag: 'voice_assistant',
                    onPressed: () => setState(() => _showVoiceOverlay = true),
                    backgroundColor: voiceService.isListening
                        ? Colors.red
                        : Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      voiceService.isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'add_item',
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/add-item', arguments: null);
                  if (mounted) {
                    context.read<ItemService>().loadItems();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
        if (_showVoiceOverlay)
          VoiceAssistantOverlay(
            onClose: () => setState(() => _showVoiceOverlay = false),
            onCommand: (command) {
              setState(() => _showVoiceOverlay = false);
              _handleVoiceCommand(command);
            },
          ),
      ],
    );
  }
}
