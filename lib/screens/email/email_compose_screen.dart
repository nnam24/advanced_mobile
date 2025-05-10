// Cập nhật màn hình soạn email để thêm tùy chọn lưu bản nháp

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import '../../models/email_model.dart';

class EmailComposeScreen extends StatefulWidget {
  final EmailModel? emailToEdit;

  const EmailComposeScreen({
    Key? key,
    this.emailToEdit,
  }) : super(key: key);

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _toController = TextEditingController();
  final _fromController = TextEditingController();
  bool _isEditing = false;
  String? _emailId;
  bool _isSending = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Kiểm tra xem có đang chỉnh sửa email không
    if (widget.emailToEdit != null) {
      _isEditing = true;
      _emailId = widget.emailToEdit!.id;
      _subjectController.text = widget.emailToEdit!.subject;
      _contentController.text = widget.emailToEdit!.content;
      _toController.text = widget.emailToEdit!.receiver;
      _fromController.text = widget.emailToEdit!.sender;
    } else {
      // Chỉ đặt giá trị mặc định nếu người dùng chưa nhập gì
      if (_fromController.text.isEmpty) {
        _fromController.text = 'Nguyên Thái Lê <lnthai21@clc.fitus.edu.vn>';
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    _toController.dispose();
    _fromController.dispose();
    super.dispose();
  }

  void _saveEmail({bool isDraft = false}) async {
    if (_formKey.currentState!.validate() || isDraft) {
      setState(() {
        isDraft ? _isSaving = true : _isSending = true;
      });

      final emailProvider = Provider.of<EmailProvider>(context, listen: false);

      final email = EmailModel(
        id: _isEditing
            ? _emailId!
            : DateTime.now().millisecondsSinceEpoch.toString(),
        subject: _subjectController.text.isEmpty && isDraft
            ? "(No subject)"
            : _subjectController.text,
        content: _contentController.text,
        sender: _fromController.text,
        receiver: _toController.text.isEmpty && isDraft
            ? "(No recipient)"
            : _toController.text,
        timestamp: DateTime.now(),
        isDraft: isDraft, // Đánh dấu là bản nháp nếu cần
      );

      try {
        if (_isEditing) {
          await emailProvider.updateEmail(email);
        } else {
          await emailProvider.createEmail(email);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft
                  ? 'Email đã được lưu dưới dạng bản nháp'
                  : (_isEditing
                      ? 'Email đã được cập nhật'
                      : 'Email đã được lưu')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isDraft ? _isSaving = false : _isSending = false;
          });
        }
      }
    }
  }

  void _saveDraft() {
    // Lưu email dưới dạng bản nháp
    _saveEmail(isDraft: true);
  }

  void _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      try {
        // Simulate sending email
        await Future.delayed(const Duration(seconds: 2));

        // Lưu email đã gửi
        _saveEmail(isDraft: false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.emailToEdit == null
            ? (widget.emailToEdit?.isDraft ?? false
                ? 'Edit Draft'
                : 'Compose Email')
            : 'Edit Email'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Nút lưu bản nháp
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isSaving || _isSending ? null : _saveDraft,
            tooltip: 'Save Draft',
          ),
          // Nút gửi email
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSending || _isSaving ? null : _sendEmail,
            tooltip: 'Send',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fromController,
                decoration: InputDecoration(
                  labelText: 'Từ',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập người gửi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                decoration: InputDecoration(
                  labelText: 'To',
                  hintText: 'Enter recipient email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Recipient email is required';
                  }
                  // Kiểm tra định dạng email
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Enter email subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Write your email here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email content is required';
                    }
                    return null;
                  },
                  maxLines: 10,
                  minLines: 5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Nút lưu bản nháp
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || _isSending ? null : _saveDraft,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nút gửi email
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending || _isSaving ? null : _sendEmail,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSending ? 'Sending...' : 'Send Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
