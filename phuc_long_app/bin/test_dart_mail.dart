import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  print('Testing Dart mailer package...');
  final username = 'mottaikhoanphu102@gmail.com';
  final password = 'anpsfjckbxmmawvj';

  // 1. Try standard gmail smtp server (port 587)
  print('Trying standard gmail(username, password)...');
  try {
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Phúc Long Test')
      ..recipients.add('nubbieim982@gmail.com')
      ..subject = 'Dart Mailer Test (Port 587)'
      ..text = 'Mã OTP thử nghiệm từ Dart mailer: 998877';

    final sendReport = await send(message, smtpServer);
    print('✅ Port 587 Success: ${sendReport.toString()}');
  } catch (e) {
    print('❌ Port 587 Error: $e');
  }

  // 2. Try port 465 SSL smtp server
  print('Trying SmtpServer port 465 ssl...');
  try {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 465,
      ssl: true,
      username: username,
      password: password,
    );
    final message = Message()
      ..from = Address(username, 'Phúc Long Test')
      ..recipients.add('nubbieim982@gmail.com')
      ..subject = 'Dart Mailer Test (Port 465 SSL)'
      ..text = 'Mã OTP thử nghiệm từ Dart mailer: 998877';

    final sendReport = await send(message, smtpServer);
    print('✅ Port 465 Success: ${sendReport.toString()}');
  } catch (e) {
    print('❌ Port 465 Error: $e');
  }
}
