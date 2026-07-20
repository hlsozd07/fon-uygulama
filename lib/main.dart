import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'features/portfolio/domain/fund_model.dart';
import 'features/history/domain/history_model.dart';
import 'features/history/domain/sell_history_model.dart';
import 'features/alarms/domain/alarm_model.dart';
import 'features/notifications/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/tefas/data/tefas_service.dart';
import 'features/dashboard/domain/portfolio_history_model.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // ignore
      }
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FundModelAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AlarmModelAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SellHistoryModelAdapter());
      
      final walletBox = await Hive.openBox<FundModel>('walletBox');
      final alarmBox = await Hive.openBox<AlarmModel>('alarmBox');
      
      final tefasService = TefasService();
      final notificationService = NotificationService();
      await notificationService.init();

      for (int i = 0; i < walletBox.length; i++) {
        final fund = walletBox.getAt(i);
        if (fund != null) {
          final tefasData = await tefasService.getFundDetails(fund.name);
          if (tefasData != null && tefasData.price > 0) {
            final updatedFund = FundModel(
              name: fund.name,
              quantity: fund.quantity,
              averageCost: fund.averageCost,
              currentPrice: tefasData.price,
              assetType: fund.assetType,
            );
            await walletBox.putAt(i, updatedFund);
            
            // Alarm kontrolü
            for (var alarm in alarmBox.values) {
              if (alarm.fundCode == fund.name && alarm.isActive) {
                bool trigger = false;
                if (alarm.isGreaterThan && tefasData.price >= alarm.targetPrice) trigger = true;
                if (!alarm.isGreaterThan && tefasData.price <= alarm.targetPrice) trigger = true;
                
                if (trigger) {
                  await notificationService.scheduleAlarm(
                    id: alarm.fundCode.hashCode,
                    title: 'Hedef Gerçekleşti: ${alarm.fundCode}',
                    body: '${alarm.fundCode} fonu hedefinize ulaştı! Fiyat: ${tefasData.price}',
                    scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
                  );
                  // Alarmı kapat (tek seferlik çalışsın)
                  final alarmIndex = alarmBox.values.toList().indexOf(alarm);
                  if (alarmIndex != -1) {
                    final updatedAlarm = AlarmModel(
                      fundCode: alarm.fundCode,
                      targetPrice: alarm.targetPrice,
                      isGreaterThan: alarm.isGreaterThan,
                      isActive: false,
                    );
                    await alarmBox.putAt(alarmIndex, updatedAlarm);
                  }
                }
              }
            }
          }
        }
      }
      // Portfolio History Kaydı
      double totalValue = 0;
      for (var f in walletBox.values) {
        totalValue += f.totalValue;
      }
      final historyBox = await Hive.openBox<PortfolioHistoryModel>('portfolioHistoryBox');
      final today = DateTime.now();
      final todayStr = "${today.year}-${today.month}-${today.day}";
      
      int existingIndex = -1;
      for (int i = 0; i < historyBox.length; i++) {
        final record = historyBox.getAt(i);
        if (record != null) {
          final recordStr = "${record.date.year}-${record.date.month}-${record.date.day}";
          if (recordStr == todayStr) {
            existingIndex = i;
            break;
          }
        }
      }
      if (existingIndex != -1) {
        await historyBox.putAt(existingIndex, PortfolioHistoryModel(date: today, totalValue: totalValue));
      } else {
        await historyBox.add(PortfolioHistoryModel(date: today, totalValue: totalValue));
      }

      return Future.value(true);
    } catch (e) {
      // log error here if necessary
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("DotEnv loading failed: $e");
  }
  await NotificationService().init();
  await initializeDateFormatting('tr_TR', null);
  
  await Hive.initFlutter();
  Hive.registerAdapter(FundModelAdapter());
  Hive.registerAdapter(HistoryModelAdapter());
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(PortfolioHistoryModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SellHistoryModelAdapter());
  await Hive.openBox<FundModel>('walletBox');
  await Hive.openBox<HistoryModel>('historyBox');
  await Hive.openBox<AlarmModel>('alarmBox');
  await Hive.openBox<PortfolioHistoryModel>('portfolioHistoryBox');
  await Hive.openBox<SellHistoryModel>('sellHistoryBox');
  
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "check_fund_prices_task",
    "checkFundPrices",
    frequency: const Duration(hours: 12),
    constraints: Constraints(networkType: NetworkType.connected),
  );
  
  runApp(const ProviderScope(child: FonTakipApp()));
}

class FonTakipApp extends StatelessWidget {
  const FonTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yatırımım app',
      theme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
    );
  }
}
