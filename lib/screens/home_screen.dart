import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
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

  @override
  void initState() {
    super.initState();
    _zipcodeController.text = '90210'; // Default for demo
    _loadFeed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Explicitly unfocus the TextField when the screen becomes active
    _zipcodeFocusNode.unfocus();
  }

  @override
  void dispose() {
    _zipcodeFocusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }

  Future<void> _loadFeed() async {
    if (_zipcodeController.text.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

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
                        focusNode: _zipcodeFocusNode, // Assign FocusNode
                        decoration: InputDecoration(
                          labelText: 'Zip Code',
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
                    ? const Center(child: Text('No posts found'))
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
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