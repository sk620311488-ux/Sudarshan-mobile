import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_history.dart';

class PremiumService {
  static const _premiumKey = 'sudarshan_premium_active';
  static const _historyKey = 'sudarshan_payment_history';

  Future<bool> isPremium() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_premiumKey) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_premiumKey, value);
  }

  Future<void> addHistory(PaymentRecord record) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_historyKey) ?? [];
    list.add(jsonEncode(record.toJson()));
    await sp.setStringList(_historyKey, list);
  }

  Future<List<PaymentRecord>> getHistory() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_historyKey) ?? [];
    return list.map((e) => PaymentRecord.fromJson(jsonDecode(e))).toList();
  }
}
