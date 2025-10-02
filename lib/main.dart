import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_taxi_chinghsien/pages/log_in.dart';
import 'package:flutter_taxi_chinghsien/pages/member/case_record.dart';
import 'package:flutter_taxi_chinghsien/pages/member/money_record.dart';
import 'package:flutter_taxi_chinghsien/pages/member/my_account_page.dart';
import 'package:flutter_taxi_chinghsien/pages/task/disclosure_dialog.dart';
import 'package:flutter_taxi_chinghsien/pages/task/home_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:http/http.dart' as http;
import 'services/route_export_service.dart';

import 'color.dart';
import 'config/serverApi.dart';
import 'firebase_options.dart';
import 'notifier_models/task_model.dart';
import 'notifier_models/user_model.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'config/amplifyconfiguration.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream = StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    await _configureAmplify();
    print('Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    print("Amplify was already configured. Was this a hot restart?");
  } catch (e) {
    print("An error occurred configuring Amplify: $e");
  }

  // 初始化資料庫，這將會觸發 onCreate 或 onUpgrade
  await RouteExportService.database;

  // LineSDK.instance.setup('1657014064').then((_) {
  //   print('LineSDK Prepared');
  // });

  // const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  //
  // final List<DarwinNotificationCategory> darwinNotificationCategories =
  // <DarwinNotificationCategory>[
  //   DarwinNotificationCategory(
  //     darwinNotificationCategoryText,
  //     actions: <DarwinNotificationAction>[
  //       DarwinNotificationAction.text(
  //         'text_1',
  //         'Action 1',
  //         buttonTitle: 'Send',
  //         placeholder: 'Placeholder',
  //       ),
  //     ],
  //   ),
  //   DarwinNotificationCategory(
  //     darwinNotificationCategoryPlain,
  //     actions: <DarwinNotificationAction>[
  //       DarwinNotificationAction.plain('id_1', 'Action 1'),
  //       DarwinNotificationAction.plain(
  //         'id_2',
  //         'Action 2 (destructive)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.destructive,
  //         },
  //       ),
  //       DarwinNotificationAction.plain(
  //         navigationActionId,
  //         'Action 3 (foreground)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.foreground,
  //         },
  //       ),
  //       DarwinNotificationAction.plain(
  //         'id_4',
  //         'Action 4 (auth required)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.authenticationRequired,
  //         },
  //       ),
  //     ],
  //     options: <DarwinNotificationCategoryOption>{
  //       DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
  //     },
  //   )
  // ];
  //
  // /// Note: permissions aren't requested here just to demonstrate that can be
  // /// done later
  // final DarwinInitializationSettings initializationSettingsDarwin =
  // DarwinInitializationSettings(
  //   requestAlertPermission: false,
  //   requestBadgePermission: false,
  //   requestSoundPermission: false,
  //   onDidReceiveLocalNotification:
  //       (int id, String? title, String? body, String? payload) async {
  //     didReceiveLocalNotificationStream.add(
  //       ReceivedNotification(
  //         id: id,
  //         title: title,
  //         body: body,
  //         payload: payload,
  //       ),
  //     );
  //   },
  //   notificationCategories: darwinNotificationCategories,
  // );
  //
  // final InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   iOS: initializationSettingsDarwin,
  // );
  //
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse:
  //       (NotificationResponse notificationResponse) {
  //     switch (notificationResponse.notificationResponseType) {
  //       case NotificationResponseType.selectedNotification:
  //         selectNotificationStream.add(notificationResponse.payload);
  //         break;
  //       case NotificationResponseType.selectedNotificationAction:
  //         if (notificationResponse.actionId == navigationActionId) {
  //           selectNotificationStream.add(notificationResponse.payload);
  //         }
  //         break;
  //     }
  //   },
  //   onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  // );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => UserModel(),
      ),
      ChangeNotifierProvider(
        create: (context) => TaskModel(),
      ),
    ],
    child: MyApp(),
  ));
}

Future<void> _configureAmplify() async {
  try {
    // Create auth and storage plugins.
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();

    // Add plugins to Amplify.
    await Amplify.addPlugins([auth, storage]);

    // Configure Amplify.
    await Amplify.configure(amplifyconfig);
  } catch (e) {
    print("An error occurred configuring Amplify: $e");
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
        textTheme: const TextTheme(
          labelLarge: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: AppColor.primary, fontSize: 20,fontWeight: FontWeight.bold, ),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 16,height: 1.6),
          bodyLarge: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(AppColor.primary),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            // 設定按鈕文字顏色為白色
            foregroundColor: WidgetStateProperty.all(Colors.white),
            // 設定按鈕背景顏色
            // backgroundColor: WidgetStateProperty.all(AppColor.primary),
          ),
        ),
        appBarTheme: const AppBarTheme(
            color: Colors.black87,
            elevation: 0,
            // 設定 AppBar 文字顏色
            foregroundColor: Colors.white, // 標題文字顏色
            // 設定返回按鈕和其他圖標的顏色
            iconTheme: IconThemeData(
              color: Colors.white, // 返回按鈕和其他圖標的顏色
            ),
            // 若你需要設定 AppBar actions 的圖標顏色：
            actionsIconTheme: IconThemeData(
              color: Colors.white, // 右側 actions 圖標的顏色
            ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // home: const MyHomePage(),
      home: const LogIn(),

      routes:  {
        '/main': (context) => const MyHomePage(),
        '/log_in': (context) => const LogIn(),
        '/money_record': (context) => const MoneyRecord(),
        '/case_record': (context) => const CaseRecord(),
      },
      builder: (context, child){
        return MediaQuery(data: MediaQuery.of(context).copyWith(textScaleFactor: 1.1), child: Container(child: child)
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');

      var userModel = context.read<UserModel>();
      userModel.updateCurrentPosition(Position(longitude: location.coords.longitude, latitude: location.coords.latitude, timestamp: DateTime.now(), accuracy: location.coords.accuracy, altitude: location.coords.altitude, heading: location.coords.heading, speed: location.coords.speed, speedAccuracy: location.coords.accuracy, altitudeAccuracy: 10.0, headingAccuracy: 5.0));
      // userModel.currentPosition = Position(longitude: location.coords.longitude, latitude: location.coords.latitude, timestamp: DateTime.now(), accuracy: location.coords.accuracy, altitude: location.coords.altitude, heading: location.coords.heading, speed: location.coords.speed, speedAccuracy: location.coords.accuracy, altitudeAccuracy: 10.0, headingAccuracy: 5.0);

      if(userModel.isOnline && userModel.token != null){
        // 直接調用位置更新，移除背景任務依賴
        _fetchUpdateLatLng(userModel.token!, userModel.currentPosition!.latitude, userModel.currentPosition!.longitude);
      }

      var taskModel = context.read<TaskModel>();
      if(taskModel.isOnTask){
        taskModel.totalDistance = location.odometer/1000.0;
        
        // 如果正在執行任務，保存位置記錄到本地資料庫
        try {
          // 只在有案件時才記錄
          if (taskModel.cases.isNotEmpty) {
            int? caseId = taskModel.cases.first.id;
            RouteExportService.saveLocationFromBg(
              location,
              caseId: caseId,
            );
          }
        } catch (e) {
          print('[location] 保存位置記錄錯誤: $e');
        }
      }
    });

    bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: true,
        startOnBoot: true,
        debug: false,
        stationaryRadius: 25,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        //add 2023/06/24 for ios
        preventSuspend: true,
        heartbeatInterval: 60,
        // ===
        backgroundPermissionRationale: bg.PermissionRationale(
            title: "允許 {applicationName} 在背景程式使用位置資訊？",
            message: "為了取得位置並提供您案件資訊，請允許在背景使用您的位置。",
            positiveAction: "允許",
            negativeAction: "取消"
        )
    )).then((bg.State state) async {
      if (!state.enabled) {
        var userModel = context.read<UserModel>();
        if(userModel.platformType=='android') {
          await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return const DisclosureDialog();}
          );
          bg.BackgroundGeolocation.start();
        }else{
          bg.BackgroundGeolocation.start();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: pageCaller(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black87, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          // onTap: _onItemTapped,
          onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
          },
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Image.asset('images/24h_tab_icon.png',height: 25,width: 40,),
                activeIcon:Image.asset('images/24h_tab_icon_selected.png',height: 25,width: 40,),
                label: "派車首頁"),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: '會員中心'),
          ],
        ),
      ),
    );
  }

  pageCaller(int index){
    switch (index){
      case 0 : { return const HomePage();}
      case 1 : { return const MyAccountPage();}
    }
  }

  Future _fetchUpdateLatLng(String token, double lat, double lng) async {
    String path = ServerApi.PATH_UPDATE_LAT_LNG;
    final queryParameters = {
      'lat': lat.toString(),
      'lng': lng.toString(),
    };

    try {
      final response = await http.get(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      ).timeout(const Duration(seconds: 5)); // 較短超時，快速失敗

      if (response.statusCode == 200) {
        print('[Location] Update success: $lat, $lng');
      } else {
        print('[Location] Update failed: ${response.statusCode}');
      }

    } catch (e) {
      print('[Location] Update failed: $e');
    }
  }
}
