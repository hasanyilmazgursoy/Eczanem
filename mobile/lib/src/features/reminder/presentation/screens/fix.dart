import 'dart:io';

void main() {
  final file = File('medication_reminders_screen.dart');
  String text = file.readAsStringSync();
  
  text = text.replaceAll(
    "' aktif hatÄ±rlatÄ±cÄ±nÄ±z var.'",
    "'\ aktif hatırlatıcınız var.'"
  );

  file.writeAsStringSync(text);
}
