import 'dart:io';

void main() {
  final file = File('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart');
  String text = file.readAsStringSync();
  
  text = text.replaceAll(
    '\'\\\\ tane aktif hatÄ±rlatÄ±cÄ±nÄ±z var.\'',
    "'\\\ tane aktif hatırlatıcınız var.'"
  );

  file.writeAsStringSync(text);
}
