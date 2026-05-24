import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Bank data model ──────────────────────────────────
class PakistanBank {
  final String name;
  final String category;   // 'wallet' | 'bank' | 'islamic'
  final String uriScheme;  // used to attempt direct open
  final String androidPkg; // used for canLaunchUrl + Play Store fallback
  final String playStoreId;// same as androidPkg, used in Play Store URL
  final String? iosAppId;  // App Store numeric ID (optional)
  final Color color;       // brand color for chip/card
  final String emoji;      // emoji icon for fast rendering (no asset needed)

  const PakistanBank({
    required this.name,
    required this.category,
    required this.uriScheme,
    required this.androidPkg,
    required this.playStoreId,
    this.iosAppId,
    required this.color,
    required this.emoji,
  });
}

// ── Master list of all Pakistani banking apps ────────
// Package IDs verified directly from Google Play Store URLs (April 2025)
const List<PakistanBank> kPakistanBanks = [

  // ── Mobile Wallets / EMIs ────────────────────────
  PakistanBank(
    name: 'JazzCash',
    category: 'wallet',
    uriScheme: 'jazzcash://',
    androidPkg: 'com.techlogix.mobilinkcustomer',
    playStoreId: 'com.techlogix.mobilinkcustomer',
    iosAppId: '1224617688',
    color: Color(0xFFD4145A),
    emoji: '🔴',
  ),
  PakistanBank(
    name: 'Easypaisa',
    category: 'wallet',
    uriScheme: 'easypaisa://',
    androidPkg: 'pk.com.telenor.phoenix',
    playStoreId: 'pk.com.telenor.phoenix',
    iosAppId: '1227725092',
    color: Color(0xFF6CC04A),
    emoji: '🟢',
  ),
  PakistanBank(
    name: 'SadaPay',
    category: 'wallet',
    uriScheme: 'sadapay://',
    androidPkg: 'com.sadapay.sadapay',
    playStoreId: 'com.sadapay.sadapay',
    iosAppId: '1485640165',
    color: Color(0xFF00C7B1),
    emoji: '🩵',
  ),
  PakistanBank(
    name: 'NayaPay',
    category: 'wallet',
    uriScheme: 'nayapay://',
    androidPkg: 'com.nayapay.app',
    playStoreId: 'com.nayapay.app',
    iosAppId: '1479836924',
    color: Color(0xFF7B2FBE),
    emoji: '🟣',
  ),

  // ── Major Commercial Banks ───────────────────────
  PakistanBank(
    name: 'HBL Mobile',
    category: 'bank',
    uriScheme: 'hblmobile://',
    androidPkg: 'com.hbl.android.hblmobilebanking',
    playStoreId: 'com.hbl.android.hblmobilebanking',
    iosAppId: '',
    color: Color(0xFF00843D),
    emoji: '🏦',
  ),
  PakistanBank(
    name: 'Meezan Bank',
    category: 'islamic',
    uriScheme: 'meezanbank://',
    androidPkg: 'invo8.meezan.mb',
    playStoreId: 'invo8.meezan.mb',
    iosAppId: '',
    color: Color(0xFF006838),
    emoji: '☪️',
  ),
  PakistanBank(
    name: 'UBL Digital',
    category: 'bank',
    uriScheme: 'ubldigital://',
    androidPkg: 'app.com.brd',
    playStoreId: 'app.com.brd',
    iosAppId: '',
    color: Color(0xFF003087),
    emoji: '🔵',
  ),
  PakistanBank(
    name: 'MCB Live',
    category: 'bank',
    uriScheme: 'mcblive://',
    androidPkg: 'com.mcb.mcblive',
    playStoreId: 'com.mcb.mcblive',
    iosAppId: '',
    color: Color(0xFFE31837),
    emoji: '🔴',
  ),
  PakistanBank(
    name: 'myABL',
    category: 'bank',
    uriScheme: 'myabl://',
    androidPkg: 'com.ofss.digx.mobile.android.allied',
    playStoreId: 'com.ofss.digx.mobile.android.allied',
    iosAppId: '1409324068',
    color: Color(0xFF00539F),
    emoji: '🔷',
  ),
  PakistanBank(
    name: 'Alfa (Alfalah)',
    category: 'bank',
    uriScheme: 'alfalfahbank://',
    androidPkg: 'com.base.bankalfalah',
    playStoreId: 'com.base.bankalfalah',
    iosAppId: '',
    color: Color(0xFF00A0DF),
    emoji: '🩵',
  ),

  // ── Mid-tier & Islamic Banks ─────────────────────
  PakistanBank(
    name: 'Bank AL Habib',
    category: 'bank',
    uriScheme: 'alhabib://',
    androidPkg: 'com.bankalhabib.mobile',
    playStoreId: 'com.bankalhabib.mobile',
    iosAppId: '',
    color: Color(0xFF862633),
    emoji: '🟤',
  ),
  PakistanBank(
    name: 'Faysal Bank',
    category: 'islamic',
    uriScheme: 'faysalbank://',
    androidPkg: 'com.faysalbank.mobilebanking',
    playStoreId: 'com.faysalbank.mobilebanking',
    iosAppId: '',
    color: Color(0xFF005A9C),
    emoji: '🔵',
  ),
  PakistanBank(
    name: 'NBP Digital',
    category: 'bank',
    uriScheme: 'nbpmobile://',
    androidPkg: 'com.nbp.mobilebanking',
    playStoreId: 'com.nbp.mobilebanking',
    iosAppId: '',
    color: Color(0xFF006400),
    emoji: '🟢',
  ),
  PakistanBank(
    name: 'Askari Bank',
    category: 'bank',
    uriScheme: 'askaribank://',
    androidPkg: 'com.askaribank.mobilebanking',
    playStoreId: 'com.askaribank.mobilebanking',
    iosAppId: '',
    color: Color(0xFF1A3A5C),
    emoji: '🔷',
  ),
  PakistanBank(
    name: 'JS Bank',
    category: 'bank',
    uriScheme: 'jsbank://',
    androidPkg: 'com.jsbank.mobilebanking',
    playStoreId: 'com.jsbank.mobilebanking',
    iosAppId: '',
    color: Color(0xFF003366),
    emoji: '🔵',
  ),
  PakistanBank(
    name: 'Standard Chartered',
    category: 'bank',
    uriScheme: 'scbpak://',
    androidPkg: 'com.scb.bma.android',
    playStoreId: 'com.scb.bma.android',
    iosAppId: '',
    color: Color(0xFF009A44),
    emoji: '🟢',
  ),
];

// ══════════════════════════════════════════════════════
// BankDetectionService — call once in initState
// Checks which of the above apps are installed
// Uses Direct Attempt strategy (does NOT gate on canLaunchUrl)
// ══════════════════════════════════════════════════════
class BankDetectionService {

  /// Returns only the banks that are installed on this device.
  /// After AndroidManifest <queries> fix, this is accurate.
  static Future<List<PakistanBank>> detectInstalled() async {
    final installed = <PakistanBank>[];
    for (final bank in kPakistanBanks) {
      try {
        // Check by package name (most reliable after manifest fix)
        final pkgUri = Uri.parse('package:${bank.androidPkg}');
        if (await canLaunchUrl(pkgUri)) {
          installed.add(bank);
          continue;
        }
        // Fallback: check by URI scheme
        final schemeUri = Uri.parse(bank.uriScheme);
        if (await canLaunchUrl(schemeUri)) {
          installed.add(bank);
        }
      } catch (_) {
        // canLaunchUrl threw — app not installed, continue
      }
    }
    return installed;
  }

  /// Attempts to open a bank app directly.
  /// Uses Direct Attempt — tries launchUrl in try/catch,
  /// does NOT depend on canLaunchUrl returning true first.
  static Future<bool> openBank(PakistanBank bank) async {
    // Try URI scheme first
    try {
      final uri = Uri.parse(bank.uriScheme);
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // REQUIRED for custom schemes
      );
      if (ok) return true;
    } catch (_) {}

    // Try Android package intent as fallback
    try {
      final pkgIntent = Uri.parse(
          'intent://#Intent;package=${bank.androidPkg};end');
      final ok = await launchUrl(
        pkgIntent,
        mode: LaunchMode.externalApplication,
      );
      if (ok) return true;
    } catch (_) {}

    return false; // both attempts failed — app not installed
  }

  /// Opens Play Store page for a bank so user can install it.
  static Future<void> openPlayStore(PakistanBank bank) async {
    final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=${bank.playStoreId}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Groups a list of banks by category for section display.
  static Map<String, List<PakistanBank>> groupByCategory(
      List<PakistanBank> banks) {
    final map = <String, List<PakistanBank>>{};
    for (final b in banks) {
      map.putIfAbsent(b.category, () => []).add(b);
    }
    return map;
  }
}
