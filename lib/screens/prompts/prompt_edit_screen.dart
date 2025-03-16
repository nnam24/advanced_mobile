import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prompt_provider.dart';
import '../../models/prompt.dart';
import '../../widgets/animated_background.dart';

class PromptEditScreen extends StatefulWidget {
  final Prompt prompt;

  const PromptEditScreen({super.key, required this.prompt});

  @override
  State<PromptEditScreen> createState() => _PromptEditScreenState();
}

class _PromptEditScreenState extends State<PromptEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late PromptCategory _selectedCategory;
  late PromptVisibility _selectedVisibility;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prompt.title);
    _contentController = TextEditingController(text: widget.prompt.content);
    _selectedCategory = widget.prompt.category;
    _selectedVisibility = widget.prompt.visibility;
    _isFavorite = widget.prompt.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updatePrompt() async {
    if (_formKey.currentState!.validate()) {
      final promptProvider =
          Provider.of<PromptProvider>(context, listen: false);

      final updatedPrompt = widget.prompt.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        visibility: _selectedVisibility,
        updatedAt: DateTime.now(),
        isFavorite: _isFavorite,
      );

      final success = await promptProvider.updatePrompt(updatedPrompt);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update prompt: ${promptProvider.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promptProvider = Provider.of<PromptProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Prompt'),
        actions: [
          TextButton(
            onPressed: promptProvider.isLoading ? null : _updatePrompt,
            child: promptProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a title for your prompt',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Content field
                  Text(
                    'Prompt Content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5),
                      ),
                    ),
                    child: TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: 'Enter the prompt content...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter prompt content';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category selection
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<PromptCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: PromptCategory.values.map((category) {
                        return DropdownMenuItem<PromptCategory>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                Prompt.getCategoryIcon(category),
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(Prompt.getCategoryName(category)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Visibility and favorite settings
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Visibility'),
                          subtitle: const Text('Who can see this prompt'),
                          trailing: SegmentedButton<PromptVisibility>(
                            segments: const [
                              ButtonSegment<PromptVisibility>(
                                value: PromptVisibility.private,
                                label: Text('Private'),
                                icon: Icon(Icons.lock),
                              ),
                              ButtonSegment<PromptVisibility>(
                                value: PromptVisibility.public,
                                label: Text('Public'),
                                icon: Icon(Icons.public),
                              ),
                            ],
                            selected: {_selectedVisibility},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _selectedVisibility = newSelection.first;
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Add to Favorites'),
                          value: _isFavorite,
                          onChanged: (value) {
                            setState(() {
                              _isFavorite = value;
                            });
                          },
                          secondary: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          promptProvider.isLoading ? null : _updatePrompt,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: promptProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
