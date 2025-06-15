import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'data/remote/file_remote_data_source.dart';
import 'presentation/pages/notes_page.dart';
import 'presentation/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'presentation/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/notes': (context) => const NotesPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const NotesPage() : const LoginPage();
  }
}

class SnapNotesApp extends StatefulWidget {
  const SnapNotesApp({super.key});

  @override
  State<SnapNotesApp> createState() => _SnapNotesAppState();
}

class _SnapNotesAppState extends State<SnapNotesApp> {
  late final FileRemoteDataSource _fileRemoteDataSource;
  final ImagePicker _picker = ImagePicker();
  String _currentPage = 'login';
  bool _isLoggedIn = false;
  String? _currentImage;
  String _currentNotes = "";
  bool _isDarkMode = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fileRemoteDataSource = FileRemoteDataSource(AuthService());
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  /**
   * Handles the login action.
   * In a real app, this would involve authentication.
   * Here, it simply sets the login status to true and navigates to the camera page.
   */
  void _handleLogin(String method) {
    setState(() {
      _isLoggedIn = true;
      _currentPage = 'camera'; // Redirect to camera after simulated login
    });
    // In a real app, this would involve Firebase Auth or similar.
    debugPrint('Logged in via: $method'); // Log the login method
  }

  /**
   * Simulates taking a picture.
   * Sets a placeholder image and some initial notes, then navigates to the notes page.
   */
  Future<void> _handleTakePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _currentImage = image.path;
          _currentNotes = "Processing image...";
        });

        try {
          final String fileUrl = await _fileRemoteDataSource.uploadFile(image);
          setState(() {
            _currentImage = fileUrl;
            _currentNotes = "Image processed successfully! Add your notes here...";
            _currentPage = 'notes';
          });
        } catch (e) {
          setState(() {
            _currentNotes = "Error processing image: $e";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /**
   * Handles saving the notes.
   * In a real application, this would send the notes to a backend database.
   * Here, it just logs them to the console.
   */
  void _handleSaveNotes() {
    debugPrint('Notes saved: $_currentNotes'); // Simulate saving notes
    // In a real app, you'd send _currentNotes to a database.
    // Optionally, show a SnackBar with "Notes saved!" feedback.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notes Saved!'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  // A helper function to create a navigation button.
  Widget _buildNavButton(String page, String label, IconData icon) {
    bool isSelected = _currentPage == page;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentPage = page;
          });
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? (_isDarkMode ? Colors.indigo[900] : Colors.indigo[700]) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.indigo[50],
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 10,
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo and Title Section
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📸', style: TextStyle(fontSize: 48, color: _isDarkMode ? Colors.indigo[300] : Colors.indigo)),
                          Text('📝', style: TextStyle(fontSize: 48, color: _isDarkMode ? Colors.indigo[300] : Colors.indigo)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Noter',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: _isDarkMode ? Colors.white : Colors.grey[800],
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture, Annotate, Organize',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),

                // Conditional Rendering of App Pages
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Builder(
                      key: ValueKey<String>(_currentPage),
                      builder: (context) {
                        switch (_currentPage) {
                          case 'login':
                            return _buildLoginPage();
                          case 'camera':
                            return _buildCameraPage();
                          case 'notes':
                            return _buildNotesPage();
                          case 'settings':
                            return _buildSettingsPage();
                          default:
                            return Container();
                        }
                      },
                    ),
                  ),
                ),

                // Navigation Bar
                if (_isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[850] : Colors.indigo[500],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavButton('camera', 'Camera', Icons.camera_alt_rounded),
                          _buildNavButton('notes', 'Notes', Icons.notes_rounded),
                          _buildNavButton('settings', 'Settings', Icons.settings_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Page Widgets ---

  Widget _buildLoginPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Login or Sign Up',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Phone Number Login
        TextFormField(
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          style: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleLogin('Phone Number'),
            icon: const Icon(Icons.phone),
            label: const Text('Login with Phone'),
          ),
        ),
        const SizedBox(height: 24),
        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(color: Colors.grey[500])),
            ),
            const Expanded(child: Divider(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 24),
        // Social Logins
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleLogin('Google'),
            icon: Image.asset(
              'assets/google_logo.png', // Placeholder, in real app, use actual asset or network image
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata), // Fallback
            ),
            label: const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!, width: 1),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleLogin('Microsoft'),
            icon: Image.asset(
              'assets/microsoft_logo.png', // Placeholder, in real app, use actual asset or network image
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.laptop_mac), // Fallback
            ),
            label: const Text('Sign in with Microsoft'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!, width: 1),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ready to Capture?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  'Live Camera View',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleTakePicture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleTakePicture,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesPage() {
    return const NotesPage(); // Use the NotesPage widget we created
  }

  Widget _buildSettingsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'App Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _isDarkMode ? Colors.white : Colors.grey[700],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Dark Mode Toggle
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dark Mode',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _isDarkMode ? Colors.white : Colors.grey[700],
                      ),
                ),
                Switch.adaptive(
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                  activeColor: Colors.indigo,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Notifications Toggle
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enable Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _isDarkMode ? Colors.white : Colors.grey[700],
                      ),
                ),
                Switch.adaptive(
                  value: true,
                  onChanged: (bool value) {
                    debugPrint('Notifications: $value');
                  },
                  activeColor: Colors.indigo,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'More settings coming soon!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
