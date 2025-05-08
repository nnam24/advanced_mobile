import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import '../../models/email_model.dart';
import 'email_list_screen.dart';
import 'email_detail_screen.dart';
import 'email_compose_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({Key? key}) : super(key: key);

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Lấy danh sách email khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmailProvider>(context, listen: false).fetchEmails();
    });
  }

  void _refreshEmails() {
    Provider.of<EmailProvider>(context, listen: false).fetchEmails();
  }

  void _selectEmail(EmailModel email) {
    Provider.of<EmailProvider>(context, listen: false).selectEmail(email);
    setState(() {
      _currentIndex = 1; // Chuyển sang tab chi tiết
    });
  }

  void _goBackToList() {
    setState(() {
      _currentIndex = 0; // Chuyển về tab danh sách
    });
  }

  void _composeEmail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailComposeScreen(),
      ),
    ).then((_) {
      // Làm mới danh sách email sau khi quay lại
      _refreshEmails();
    });
  }

  void _editEmail(EmailModel email) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(emailToEdit: email),
      ),
    ).then((_) {
      // Làm mới danh sách email sau khi quay lại
      _refreshEmails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<EmailProvider>(
      builder: (context, emailProvider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Danh sách email
              EmailListScreen(
                emails: emailProvider.emails,
                isLoading: emailProvider.isLoading,
                onEmailSelected: _selectEmail,
                onRefresh: _refreshEmails,
                onComposeEmail: _composeEmail,
              ),

              // Tab 1: Chi tiết email
              EmailDetailScreen(
                onEditEmail: _editEmail,
                onBackPressed: _goBackToList,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              // Chỉ cho phép chuyển từ chi tiết về danh sách
              // Không cho phép chuyển từ danh sách sang chi tiết nếu không có email được chọn
              if (index == 0 || (index == 1 && emailProvider.selectedEmail != null)) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            backgroundColor: colorScheme.surface,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.inbox),
                label: 'Inbox',
                tooltip: 'View email list',
              ),
              NavigationDestination(
                icon: const Icon(Icons.email),
                label: 'Details',
                tooltip: 'View email details',
                enabled: emailProvider.selectedEmail != null,
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
            onPressed: _composeEmail,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.edit),
            tooltip: 'Compose New Email',
          )
              : null,
        );
      },
    );
  }
}
