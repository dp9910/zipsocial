import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart'; // Corrected import for AppUser
import '../services/post_service.dart';
import '../services/supabase_auth_service.dart'; // Import SupabaseAuthService
import '../widgets/post_card.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _zipcodeController = TextEditingController();
  final FocusNode _zipcodeFocusNode = FocusNode(); // Add FocusNode
  List<Post> _posts = [];
  final List<PostTag> _selectedTags = [];
  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _lastKnownZipcode;

  @override
  void initState() {
    super.initState();
    _initializeFeed();
  }

  Future<void> _initializeFeed() async {
    final userProfile = await SupabaseAuthService.getUserProfile();
    final newZipcode = userProfile?.preferredZipcode ?? '';
    
    if (newZipcode.isNotEmpty) {
      setState(() {
        _zipcodeController.text = newZipcode;
      });
      _loadFeed();
    } else {
      // For new users, don't set a default zipcode, let them input their own
      setState(() {
        _zipcodeController.text = '';
        _posts = []; // Clear posts for new users
      });
    }
    
    _lastKnownZipcode = newZipcode;
    _hasInitialized = true;
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // Re-initialize if we haven't done so yet
    if (!_hasInitialized) {
      _initializeFeed();
    } else {
      // Check if the user's preferred zipcode has changed (e.g., after profile setup)
      final userProfile = await SupabaseAuthService.getUserProfile();
      final currentZipcode = userProfile?.preferredZipcode ?? '';
      
      if (currentZipcode != _lastKnownZipcode) {
        _initializeFeed();
      }
    }
  }

  @override
  void dispose() {
    _zipcodeController.dispose();
    _zipcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    if (_zipcodeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final rawResponse = await PostService.getFeedRaw(
        zipcode: _zipcodeController.text,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
      );
      final posts = rawResponse.map<Post>((json) => Post.fromJson(json)).toList();
      setState(() => _posts = posts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTag(PostTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _loadFeed();
  }

  void refreshFeed() {
    _loadFeed();
  }

  // Method to refresh the entire feed including user profile
  void refreshFromProfile() {
    _hasInitialized = false;
    _initializeFeed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade900 
            : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Home Feed',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade900 
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black26 
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _zipcodeController,
                          focusNode: _zipcodeFocusNode,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Enter Zip Code',
                            hintText: '',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: AppTheme.primary,
                            ),
                            suffixIcon: _zipcodeController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _zipcodeController.clear();
                                    });
                                  },
                                )
                              : null,
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade700 
                                    : AppTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade700 
                                    : AppTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {}); // Rebuild to show/hide clear button
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _loadFeed();
                            }
                            FocusScope.of(context).unfocus();
                          },
                          onEditingComplete: () {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _loadFeed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Category filters
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: PostTag.values.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    final tagColor = _getTagColor(tag);
                    
                    return GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? tagColor 
                              : (Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey.shade800 
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected 
                                ? tagColor 
                                : (Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: tagColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTagIcon(tag),
                              size: 16,
                              color: isSelected 
                                  ? Colors.white
                                  : tagColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag.name,
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white
                                    : (Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade300 
                                        : Colors.grey.shade700),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Feed
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade100,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Loading local posts...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _posts.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade800 
                                        : Colors.grey.shade100,
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _zipcodeController.text.isEmpty 
                                        ? Icons.search_outlined
                                        : Icons.post_add_outlined,
                                    size: 48,
                                    color: AppTheme.primary.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _zipcodeController.text.isEmpty 
                                    ? 'Discover Your Community'
                                    : 'Be the First to Post!',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade300 
                                        : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _zipcodeController.text.isEmpty 
                                    ? 'Enter your zip code above to connect with people in your area and see what\'s happening locally'
                                    : 'No posts yet for ${_zipcodeController.text}. Share what\'s happening in your area and start the conversation!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade500 
                                        : Colors.grey.shade500,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: PostCard(
                                post: post,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
    );
  }

  Color _getTagColor(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Colors.red.shade600;
      case PostTag.funFacts:
        return Colors.purple.shade600;
      case PostTag.events:
        return Colors.green.shade600;
      case PostTag.random:
        return Colors.blue.shade600;
    }
  }

  IconData _getTagIcon(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Icons.newspaper;
      case PostTag.funFacts:
        return Icons.lightbulb;
      case PostTag.events:
        return Icons.event;
      case PostTag.random:
        return Icons.casino;
    }
  }
}