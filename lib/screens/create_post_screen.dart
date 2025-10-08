import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../config/theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _whenController = TextEditingController();
  final _costController = TextEditingController();
  final _parkingController = TextEditingController();
  final _linkController = TextEditingController();
  final _contactController = TextEditingController();
  
  PostTag _selectedTag = PostTag.random;
  bool _isLoading = false;

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty || _zipcodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_selectedTag == PostTag.events && _whenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event details are required for events')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? eventDetails;
      if (_selectedTag == PostTag.events) {
        eventDetails = {
          'when': _whenController.text,
          'cost': _costController.text,
          'parking': _parkingController.text,
          'link': _linkController.text,
          'contact': _contactController.text,
        };
      }

      await PostService.createPost(
        content: _contentController.text,
        zipcode: _zipcodeController.text,
        tag: _selectedTag,
        eventDetails: eventDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Color(0xFF8CE830),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate post was created
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Post'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar + Text Area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.person, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          minLines: 4,
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Zip Code
                  TextField(
                    controller: _zipcodeController,
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
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PostTag.values.map((tag) {
                      final isSelected = _selectedTag == tag;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTag = tag);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? AppTheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                ? AppTheme.primary 
                                : AppTheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                tag.name,
                                style: TextStyle(
                                  color: isSelected 
                                    ? AppTheme.primary 
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Event Details (if events selected)
                  if (_selectedTag == PostTag.events) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Event Details:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildEventField('When *', _whenController),
                    _buildEventField('Cost', _costController),
                    _buildEventField('Parking', _parkingController),
                    _buildEventField('Link', _linkController),
                    _buildEventField('Contact', _contactController),
                  ],
                  
                  // Add some bottom padding to ensure content is above keyboard
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom action bar (like in HTML design)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera),
                  onPressed: () {
                    // TODO: Image picker
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () {
                    // TODO: Video picker
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () {
                    // TODO: Gallery picker
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.alternate_email),
                  onPressed: () {
                    // TODO: Mention users
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primary.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primary.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}