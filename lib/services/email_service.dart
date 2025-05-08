import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_model.dart';
import '../models/user.dart';

class EmailService {
  static const String _baseUrl = 'https://api.jarvis.cx/api/v1';
  static const String _baseEmailsStorageKey = 'saved_emails';
  final String _authToken = 'eyJhbGciOiJFUzI1NiIsImtpZCI6InFsWUdfYXNMRTI0VSJ9.eyJzdWIiOiIyNTk4Yjk3YS02MWU0LTQ0Y2UtYWJjNC0xMjQ5N2RhZjA2Y2MiLCJicmFuY2hJZCI6Im1haW4iLCJpc3MiOiJodHRwczovL2FjY2Vzcy10b2tlbi5qd3Qtc2lnbmF0dXJlLnN0YWNrLWF1dGguY29tIiwiaWF0IjoxNzQzNzg3MzY5LCJhdWQiOiI0NWExZTJmZC03N2VlLTQ4NzItOWZiNy05ODdiOGMxMTk2MzMiLCJleHAiOjE3NTE1NjMzNjl9.oqYM5aMMiuF-Cg9RpcbmvAEw9a3SRpckKr2NyxQ58aMM-yBRzR9y3ogaeMJHzeXtVNtacuFsMd04roDlGGtwKQ';
  final String _guidHeader = 'baf60c1e-c61b-496d-ad92-f5aeeadf4def';

  // Người dùng hiện tại
  final User? _currentUser;

  // Constructor nhận thông tin người dùng hiện tại
  EmailService({User? currentUser}) : _currentUser = currentUser;

  // Tạo khóa lưu trữ duy nhất cho mỗi người dùng
  String get _emailsStorageKey {
    if (_currentUser != null) {
      // Sử dụng email của người dùng làm phần của khóa
      return '${_baseEmailsStorageKey}_${_currentUser!.email}';
    }
    // Nếu không có người dùng, sử dụng khóa mặc định
    return _baseEmailsStorageKey;
  }

  // Lấy danh sách email từ SharedPreferences
  Future<List<EmailModel>> getEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailsJson = prefs.getStringList(_emailsStorageKey);

      // Nếu có email đã lưu, trả về danh sách đó
      if (emailsJson != null && emailsJson.isNotEmpty) {
        return emailsJson
            .map((json) => EmailModel.fromJson(jsonDecode(json)))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sắp xếp theo thời gian mới nhất
      }

      // Nếu không có email đã lưu, tạo danh sách email mẫu
      final mockEmails = _createMockEmails();

      // Lưu danh sách email mẫu vào SharedPreferences
      await prefs.setStringList(
        _emailsStorageKey,
        mockEmails.map((email) => jsonEncode(email.toJson())).toList(),
      );

      return mockEmails;
    } catch (e) {
      print('Error getting emails: $e');
      return _createMockEmails(); // Trả về email mẫu nếu có lỗi
    }
  }

  // Tạo danh sách email mẫu
  List<EmailModel> _createMockEmails() {
    // Xác định người nhận dựa trên người dùng hiện tại
    final receiver = _currentUser != null
        ? '${_currentUser!.name} <${_currentUser!.email}>'
        : 'Nguyên Thái Lê <lnthai21@clc.fitus.edu.vn>';

    return [
      EmailModel(
        id: '1',
        subject: 'Mời phỏng vấn vị trí Kỹ sư AI tại VinAI',
        content: 'Kính gửi anh/chị ${_currentUser?.name ?? "Nguyên Thái Lê"},\n\nChúng tôi xin gửi lời cảm ơn vì sự quan tâm của anh/chị đối với vị trí Kỹ sư AI tại VinAI. Sau khi xem xét hồ sơ của anh/chị, chúng tôi rất ấn tượng với kinh nghiệm và kỹ năng của anh/chị, và muốn mời anh/chị tham gia buổi phỏng vấn.\n\nThời gian: 14:00, Thứ Tư, ngày 15/05/2024\nĐịa điểm: VinAI Research, Tầng 17, Tòa nhà Keangnam Landmark 72, Phạm Hùng, Hà Nội\nHình thức: Phỏng vấn trực tiếp\n\nBuổi phỏng vấn sẽ kéo dài khoảng 1 giờ và bao gồm các câu hỏi về kinh nghiệm, kỹ năng kỹ thuật và một bài kiểm tra ngắn. Vui lòng mang theo CMND/CCCD và bản sao bằng cấp liên quan.\n\nXin vui lòng xác nhận sự tham gia của anh/chị bằng cách trả lời email này. Nếu thời gian trên không phù hợp, vui lòng đề xuất thời gian thay thế.\n\nChúng tôi rất mong được gặp anh/chị!\n\nTrân trọng,\nPhòng Nhân sự\nVinAI Research',
        sender: 'Phòng Nhân sự VinAI <hr@vinai.io>',
        receiver: receiver,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      EmailModel(
        id: '2',
        subject: 'Xác nhận đơn hàng #VN12345678 từ Tiki',
        content: 'Kính gửi Quý khách ${_currentUser?.name ?? "Nguyên Thái Lê"},\n\nCảm ơn Quý khách đã đặt hàng tại Tiki. Đơn hàng #VN12345678 của Quý khách đã được xác nhận thành công.\n\nThông tin đơn hàng:\n- Sản phẩm: Laptop Dell XPS 13 9310 (i7-1165G7, 16GB RAM, 512GB SSD)\n- Số lượng: 1\n- Giá: 32.990.000đ\n- Phí vận chuyển: 0đ (Freeship)\n- Tổng thanh toán: 32.990.000đ\n- Phương thức thanh toán: Thẻ tín dụng/ghi nợ\n- Địa chỉ giao hàng: 123 Nguyễn Văn Linh, Quận 7, TP.HCM\n- Thời gian giao hàng dự kiến: 10/05/2024 - 12/05/2024\n\nQuý khách có thể theo dõi trạng thái đơn hàng tại trang web Tiki hoặc ứng dụng Tiki trên điện thoại.\n\nNếu có bất kỳ thắc mắc nào, vui lòng liên hệ với chúng tôi qua hotline 1900-6035 hoặc email hotro@tiki.vn.\n\nTrân trọng,\nĐội ngũ Chăm sóc Khách hàng Tiki',
        sender: 'Tiki <no-reply@tiki.vn>',
        receiver: receiver,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        isRead: true,
      ),
      EmailModel(
        id: '3',
        subject: 'Thông báo về việc đăng ký tham gia Hội thảo Khoa học Công nghệ 2024',
        content: 'Kính gửi các bạn sinh viên,\n\nTrường Đại học Khoa học Tự nhiên, ĐHQG-HCM trân trọng thông báo về việc tổ chức Hội thảo Khoa học Công nghệ 2024 dành cho sinh viên với chủ đề "Ứng dụng Trí tuệ Nhân tạo trong Khoa học Dữ liệu".\n\nThời gian: 08:00 - 17:00, Thứ Bảy, ngày 25/05/2024\nĐịa điểm: Hội trường A, Trường ĐH Khoa học Tự nhiên, 227 Nguyễn Văn Cừ, Quận 5, TP.HCM\n\nHội thảo sẽ có sự tham gia của các chuyên gia hàng đầu trong lĩnh vực AI và Data Science từ các công ty công nghệ lớn như Google, Microsoft, VinAI, FPT Software...\n\nCác bạn sinh viên quan tâm vui lòng đăng ký tham gia tại link: https://forms.hcmus.edu.vn/htkh2024 trước ngày 20/05/2024.\n\nRất mong nhận được sự tham gia của các bạn!\n\nTrân trọng,\nPhòng Khoa học Công nghệ\nTrường ĐH Khoa học Tự nhiên, ĐHQG-HCM',
        sender: 'Phòng KHCN <khcn@hcmus.edu.vn>',
        receiver: receiver,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      EmailModel(
        id: '4',
        subject: 'Tài liệu cho buổi thuyết trình nhóm môn Học máy',
        content: 'Chào ${_currentUser?.name?.split(' ').last ?? "Thái"},\n\nMình gửi cho bạn tài liệu đã chuẩn bị cho buổi thuyết trình nhóm môn Học máy vào tuần sau. Mình đã hoàn thành phần về mô hình Random Forest và Gradient Boosting như đã thảo luận.\n\nTrong file đính kèm có:\n1. Slide thuyết trình (PowerPoint)\n2. Code demo (Jupyter Notebook)\n3. Báo cáo phân tích (PDF)\n\nMình nghĩ chúng ta nên họp nhóm một lần nữa vào thứ Sáu để chạy thử toàn bộ bài thuyết trình. Bạn có thể vào lúc 14h được không?\n\nNgoài ra, mình có một số ý tưởng để cải thiện độ chính xác của mô hình, mình sẽ trao đổi thêm khi gặp mặt.\n\nNhắn mình biết nếu bạn cần điều chỉnh gì nhé!\n\nThân,\nMinh Tuấn',
        sender: 'Minh Tuấn <tuanpm@gmail.com>',
        receiver: receiver,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      EmailModel(
        id: '5',
        subject: 'Thông báo bảo trì hệ thống ngày 12/05/2024',
        content: 'Kính gửi Quý khách hàng,\n\nNgân hàng BIDV trân trọng thông báo về việc bảo trì hệ thống định kỳ như sau:\n\nThời gian bảo trì: 01:00 - 05:00, Chủ Nhật, ngày 12/05/2024\n\nTrong thời gian này, các dịch vụ sau sẽ tạm ngưng hoạt động:\n- Ngân hàng điện tử BIDV Online\n- Ứng dụng BIDV SmartBanking\n- Dịch vụ thanh toán qua thẻ\n- Dịch vụ ATM/CDM\n\nCác giao dịch tại quầy vẫn hoạt động bình thường trong giờ làm việc.\n\nChúng tôi sẽ nỗ lực hoàn thành công tác bảo trì trong thời gian sớm nhất. Ngân hàng BIDV rất tiếc về sự bất tiện này và mong Quý khách thông cảm.\n\nMọi thắc mắc, Quý khách vui lòng liên hệ Hotline 1900 9247 để được hỗ trợ.\n\nTrân trọng,\nNgân hàng BIDV',
        sender: 'BIDV <thongbao@bidv.com.vn>',
        receiver: receiver,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: false,
      ),
    ];
  }

  // Lưu email vào SharedPreferences
  Future<EmailModel> saveEmail(EmailModel email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailsJson = prefs.getStringList(_emailsStorageKey) ?? [];

      // Kiểm tra xem email đã tồn tại chưa
      final existingIndex = emailsJson.indexWhere((json) {
        final existingEmail = EmailModel.fromJson(jsonDecode(json));
        return existingEmail.id == email.id;
      });

      if (existingIndex >= 0) {
        // Cập nhật email hiện có
        emailsJson[existingIndex] = jsonEncode(email.toJson());
      } else {
        // Thêm email mới
        emailsJson.add(jsonEncode(email.toJson()));
      }

      await prefs.setStringList(_emailsStorageKey, emailsJson);
      return email;
    } catch (e) {
      print('Error saving email: $e');
      throw Exception('Không thể lưu email: $e');
    }
  }

  // Xóa email từ SharedPreferences
  Future<bool> deleteEmail(String emailId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailsJson = prefs.getStringList(_emailsStorageKey) ?? [];

      final filteredEmails = emailsJson.where((json) {
        final email = EmailModel.fromJson(jsonDecode(json));
        return email.id != emailId;
      }).toList();

      await prefs.setStringList(_emailsStorageKey, filteredEmails);
      return true;
    } catch (e) {
      print('Error deleting email: $e');
      return false;
    }
  }

  // Xóa tất cả email của người dùng hiện tại
  Future<bool> deleteAllEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailsStorageKey);
      return true;
    } catch (e) {
      print('Error deleting all emails: $e');
      return false;
    }
  }

  // Lấy ý tưởng phản hồi cho email
  Future<List<String>> getReplyIdeas({
    required String emailContent,
    required String subject,
    required String sender,
    required String receiver,
    required String action,
    String language = 'vietnamese',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai-email/reply-ideas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'x-jarvis-guid': _guidHeader,
        },
        body: jsonEncode({
          'action': action,
          'email': emailContent,
          'metadata': {
            'context': [],
            'subject': subject,
            'sender': sender,
            'receiver': receiver,
            'language': language
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['ideas'] ?? []);
      } else {
        throw Exception('Failed to get reply ideas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting reply ideas: $e');
    }
  }

  // Tạo phản hồi email đầy đủ
  Future<Map<String, dynamic>> generateEmailResponse({
    required String emailContent,
    required String mainIdea,
    required String action,
    required String subject,
    required String sender,
    required String receiver,
    String language = 'vietnamese',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'x-jarvis-guid': _guidHeader,
        },
        body: jsonEncode({
          'mainIdea': mainIdea,
          'action': 'Reply to this email',
          'email': emailContent,
          'metadata': {
            'context': [],
            'subject': subject,
            'sender': sender,
            'receiver': receiver,
            'style': {
              'length': 'long',
              'formality': 'neutral',
              'tone': 'friendly'
            },
            'language': language
          },
          'availableImprovedActions': [
            'More engaging',
            'More Informative',
            'Add humor',
            'Add details',
            'More apologetic',
            'Make it polite',
            'Add clarification',
            'Simplify language',
            'Improve structure',
            'Add empathy',
            'Add a summary',
            'Insert professional jargon',
            'Make longer',
            'Make shorter'
          ]
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating email: $e');
    }
  }

  // Quy trình 2 bước: Lấy ý tưởng và tạo email
  Future<Map<String, dynamic>> generateEmailWithAction({
    required String emailContent,
    required String subject,
    required String sender,
    required String receiver,
    required String action,
    String language = 'vietnamese',
  }) async {
    try {
      // Bước 1: Lấy ý tưởng phản hồi
      final ideas = await getReplyIdeas(
        emailContent: emailContent,
        subject: subject,
        sender: sender,
        receiver: receiver,
        action: action,
        language: language,
      );

      if (ideas.isEmpty) {
        throw Exception('No reply ideas generated');
      }

      // Lấy ý tưởng đầu tiên làm mainIdea
      final mainIdea = ideas[0];

      // Bước 2: Tạo email phản hồi đầy đủ
      final response = await generateEmailResponse(
        emailContent: emailContent,
        mainIdea: mainIdea,
        action: action,
        subject: subject,
        sender: sender,
        receiver: receiver,
        language: language,
      );

      // Thêm tất cả ý tưởng vào response
      response['ideas'] = ideas;

      return response;
    } catch (e) {
      throw Exception('Error in email generation process: $e');
    }
  }
}
