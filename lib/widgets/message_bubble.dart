import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLoading;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLoading = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageBubble &&
        other.message.id == message.id &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => message.id.hashCode ^ isLoading.hashCode;

  String _formatCode(String content) {
    if (content.contains('\`\`\`')) {
      final parts = content.split('\`\`\`');
      List<String> formatted = [];

      for (var i = 0; i < parts.length; i++) {
        if (i % 2 == 1) {
          // Code block
          String code = parts[i];
          // Remove language identifier if present
          if (code.contains('\n')) {
            code = code.substring(code.indexOf('\n')).trim();
          }
          formatted.add(_buildCodeBlock(code));
        } else {
          // Regular text
          if (parts[i].trim().isNotEmpty) {
            formatted.add(parts[i].trim());
          }
        }
      }

      return formatted.join('\n\n');
    }
    return content;
  }

  String _buildCodeBlock(String code) {
    return code.split('\n').map((line) {
      // Add proper indentation
      final indentLevel = line.indexOf(RegExp(r'[^\s]'));
      if (indentLevel > 0) {
        return '${' ' * indentLevel}$line';
      }
      return line;
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message header with avatar and name
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 8,
              right: isUser ? 8 : 0,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) _buildAvatar(context, isUser),
                const SizedBox(width: 8),
                Text(
                  isUser
                      ? 'You'
                      : message.timestamp != null
                          ? 'AI assistant'
                          : 'AI assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (message.timestamp != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isUser) ...[
                  const SizedBox(width: 8),
                  _buildAvatar(context, isUser),
                ],
              ],
            ),
          ),

          // Message bubble
          Container(
            margin: EdgeInsets.only(
              left: isUser ? 50 : 0,
              right: isUser ? 0 : 50,
            ),
            child: _buildMessageContent(context, isUser, isDarkMode),
          ),

          // Action buttons for assistant messages
          if (!isLoading && !isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    context,
                    Icons.thumb_up_outlined,
                    'Helpful',
                    () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Feedback recorded: Helpful'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    Icons.thumb_down_outlined,
                    'Not helpful',
                    () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Feedback recorded: Not helpful'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    Icons.copy,
                    'Copy',
                    () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant)
                .withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy_outlined,
          color: isUser ? Colors.white : Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, bool isUser, bool isDarkMode) {
    if (isLoading) {
      return _buildGlassmorphicContainer(
        context,
        isUser,
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thinking...',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if this is an image message
    if (message.hasImage) {
      return _buildGlassmorphicContainer(
        context,
        isUser,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.error_outline, size: 40),
                      ),
                    );
                  },
                ),
              ),
              if (message.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Check if message contains code to optimize rendering
    final containsCode = message.content.contains('\`\`\`');

    return _buildGlassmorphicContainer(
      context,
      isUser,
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: containsCode
            ? _buildCodeContent(context)
            : SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
      ),
    );
  }

  Widget _buildCodeContent(BuildContext context) {
    final parts = message.content.split('\`\`\`');
    List<Widget> contentWidgets = [];

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].trim().isEmpty) continue;

      if (i % 2 == 1) {
        // Code block
        String code = parts[i];
        // Remove language identifier if present
        if (code.contains('\n')) {
          final firstNewline = code.indexOf('\n');
          final language = code.substring(0, firstNewline).trim();
          code = code.substring(firstNewline).trim();

          contentWidgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        language.isNotEmpty ? language : 'Code',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Regular text
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SelectableText(
              parts[i],
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildGlassmorphicContainer(
      BuildContext context, bool isUser, Widget child) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: CustomAnimationBuilder<double>(
          control: Control.play,
          tween: 0.0.tweenTo(1.0),
          duration: 500.milliseconds,
          curve: Curves.easeOutQuad,
          builder: (context, value, _) {
            return Container(
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor.withOpacity(0.15 * value)
                    : surfaceColor.withOpacity(0.5 * value),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? primaryColor.withOpacity(0.2 * value)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.05 * value),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primaryColor.withOpacity(0.1 * value)
                        : Colors.black.withOpacity(0.03 * value),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
