import 'package:flutter/material.dart';
import '../models/post.dart';
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
    // Defer initialization to after the first frame renders for faster startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFeed();
      }
    });
  }

  Future<void> _initializeFeed() async {
    // Use cached profile to avoid redundant API calls
    final userProfile = await SupabaseAuthService.getUserProfile();
    final newZipcode = userProfile?.preferredZipcode ?? '';
    
    if (newZipcode.isNotEmpty) {
      setState(() {
        _zipcodeController.text = newZipcode;
      });
      // Load feed asynchronously without blocking UI
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

  void _dismissKeyboardCompletely() {
    // Comprehensive keyboard dismissal for zip code field
    FocusScope.of(context).unfocus();
    _zipcodeFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    // Additional dismissal for persistent numeric keyboards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _zipcodeFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  void deactivate() {
    // Dismiss keyboard when screen becomes inactive (tab switch, navigation, etc.)
    _dismissKeyboardCompletely();
    super.deactivate();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping anywhere on screen
          _dismissKeyboardCompletely();
        },
        child: CustomScrollView(
        slivers: [
          // Compact App Bar with Search
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade900 
                : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
                child: Row(
                  children: [
                    // App logo/icon (smaller)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search field (takes most space)
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _zipcodeController,
                          focusNode: _zipcodeFocusNode,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Enter zip code',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            suffixIcon: _zipcodeController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 15),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {});
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _loadFeed();
                            }
                            _dismissKeyboardCompletely();
                          },
                          onEditingComplete: () {
                            _dismissKeyboardCompletely();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search button (compact)
                    Container(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          _dismissKeyboardCompletely();
                          _loadFeed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Filters (Horizontal Scroll)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // "All" filter option
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCompactFilterChip(
                        label: 'All',
                        icon: Icons.apps,
                        isSelected: _selectedTags.isEmpty,
                        onTap: () {
                          setState(() {
                            _selectedTags.clear();
                          });
                          _loadFeed();
                        },
                        color: AppTheme.primary,
                      ),
                    ),
                    // Category filters
                    ...PostTag.values.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCompactFilterChip(
                          label: _getTagDisplayName(tag),
                          icon: _getTagIcon(tag),
                          isSelected: _selectedTags.contains(tag),
                          onTap: () => _toggleTag(tag),
                          color: _getTagColor(tag),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade200,
            ),
          ),
          // Feed Content
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading posts...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _posts.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
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
                                child: Icon(
                                  _zipcodeController.text.isEmpty 
                                      ? Icons.location_searching
                                      : Icons.post_add,
                                  size: 40,
                                  color: AppTheme.primary.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _zipcodeController.text.isEmpty 
                                  ? 'Find Your Community'
                                  : 'No Posts Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade300 
                                      : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _zipcodeController.text.isEmpty 
                                  ? 'Enter your zip code to see local posts'
                                  : 'Be the first to post in ${_zipcodeController.text}!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade500 
                                      : Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = _posts[index];
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16, 
                              index == 0 ? 16 : 8, 
                              16, 
                              index == _posts.length - 1 ? 16 : 8
                            ),
                            child: PostCard(
                              post: post,
                              onPostUpdated: _loadFeed,
                            ),
                          );
                        },
                        childCount: _posts.length,
                      ),
                    ),
        ],
        ),
      ),
    );
  }

  // Compact filter chip widget
  Widget _buildCompactFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(isDark ? 0.6 : 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? (isDark ? Colors.black : Colors.white)
                  : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? (isDark ? Colors.black : Colors.white)
                    : color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTagDisplayName(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return 'News';
      case PostTag.funFacts:
        return 'Fun Facts';
      case PostTag.events:
        return 'Events';
      case PostTag.random:
        return 'Random';
    }
  }

  Color _getTagColor(PostTag tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (tag) {
      case PostTag.news:
        return isDark ? Colors.red.shade400 : Colors.red.shade600;
      case PostTag.funFacts:
        return isDark ? Colors.purple.shade400 : Colors.purple.shade600;
      case PostTag.events:
        return isDark ? Colors.green.shade400 : Colors.green.shade600;
      case PostTag.random:
        return isDark ? Colors.blue.shade400 : Colors.blue.shade600;
    }
  }

  IconData _getTagIcon(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Icons.article_outlined;
      case PostTag.funFacts:
        return Icons.lightbulb_outline;
      case PostTag.events:
        return Icons.event_outlined;
      case PostTag.random:
        return Icons.shuffle;
    }
  }
}