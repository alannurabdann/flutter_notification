import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';

class NotifController extends GetxController{
  static final box = GetStorage();
  String get fcmToken => box.read('fcmToken') ?? '';

  var logger = new Logger();
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    initFirebase();
  }

  Future<void> initFirebase() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logger.e('User granted permission');
      // TODO: handle the received notifications
    } else {
      logger.e('User declined or has not accepted permission');
    }


    final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: null,
        macOS: null);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: null);

    //get token
    FirebaseMessaging.instance.getToken().then((String? onValue) async {
      logger.i('onFcmGetToken : $onValue');
      setFcmToken(onValue);
    });

    //on background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    //on foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      RemoteNotification? notification = message.notification;
      String eventID = "asdnasjdnaskdnbaihbd2in1en213123";
      int notificationId = eventID.hashCode;

      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
            notificationId,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                importance: Importance.max,
                playSound: true,
                showProgress: true,
                priority: Priority.high,
                color: Colors.blue,
                styleInformation: BigTextStyleInformation(notification.body.toString()),
              ),
            ));
      }
    });
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  void setFcmToken(String? data) {
    box.write('fcmToken', data);
    logger.e(data);
  }

}