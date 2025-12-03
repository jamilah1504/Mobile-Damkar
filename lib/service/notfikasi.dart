import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 1. Handler untuk Background (Harus di luar class, top-level function)
// Fungsi ini berjalan ketika aplikasi ditutup atau di background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jika perlu akses database di background, initializeApp harus dipanggil disini juga
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // Singleton pattern (opsional, tapi bagus agar instance tetap satu)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Setup Channel Android (PENTING: importance.max membuat popup muncul)
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // ID Channel
    'High Importance Notifications', // Nama Channel
    description: 'Channel ini digunakan untuk notifikasi penting (popup)',
    importance: Importance.max, // MAX = Muncul Popup + Suara
    playSound: true,
  );

  Future<void> initialize() async {
    // A. Request Permission (Wajib untuk Android 13+ dan iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined permission');
      return;
    }

    // B. Setup Local Notification Settings
    // Pastikan icon 'ic_launcher' atau 'app_icon' ada di android/app/src/main/res/drawable/
    // Jika tidak yakin nama iconnya, cek folder drawable, defaultnya 'ic_launcher' atau '@mipmap/ic_launcher'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Setup untuk iOS (jika nanti dikembangkan ke iOS)
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // C. Initialize Local Plugin
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Disini logika jika notifikasi di-klik saat aplikasi terbuka
        if (response.payload != null) {
          print('Notifikasi diklik dengan payload: ${response.payload}');
          //Contoh: Navigator.pushNamed(context, '/detail', arguments: response.payload);
        }
      },
    );

    // D. Buat Channel di Android System
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // E. Setup Background Handler FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // F. Setup Foreground Handler (Saat aplikasi dibuka)
    // FCM default tidak memunculkan popup jika app dibuka, jadi kita buat manual pakai LocalNotification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Jika ada notifikasi dan data android valid, tampilkan popup
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android.smallIcon, // Mengambil icon dari payload FCM
              importance: Importance.max, // PENTING: Popup
              priority: Priority.high,    // PENTING: Prioritas tinggi
              playSound: true,
            ),
          ),
          payload: message.data.toString(), // Data tambahan dikirim ke 'onDidReceiveNotificationResponse'
        );
      }
    });
  }

  // Fungsi Helper untuk mengambil Token FCM
  Future<String?> getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print("Error getting token: $e");
      return null;
    }
  }
}