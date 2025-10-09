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
        print('Zipcode changed from $_lastKnownZipcode to $currentZipcode, refreshing feed');
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
      print('Raw Supabase response for feed: $rawResponse'); // Add this line
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        automaticallyImplyLeading: false,
        title: const Text('Feed'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigation handled by bottom nav
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _zipcodeController,
                        focusNode: _zipcodeFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Zip Code',
                          hintText: 'Enter zip code',
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show/hide clear button
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _loadFeed();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadFeed,
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: PostTag.values.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleTag(tag),
                      backgroundColor: Colors.transparent,
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      checkmarkColor: AppTheme.primary,
                      side: BorderSide(
                        color: isSelected 
                          ? AppTheme.primary 
                          : AppTheme.primary.withOpacity(0.3),
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
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _zipcodeController.text.isEmpty 
                                  ? 'Enter your zip code to see local posts'
                                  : 'Be the first one to post for this zip code',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _zipcodeController.text.isEmpty 
                                  ? 'Connect with your local community'
                                  : 'Share what\'s happening in your area!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
    );
  }
}