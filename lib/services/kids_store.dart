import 'dart:async';

import 'package:ark_core/auth.dart';
import 'package:ark_core/purchase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/progress/progress_keys.dart';
import 'progress_service.dart';

/// Store-facing setup for KIDS: one-time unlock, parent gate, login and
/// cloud progress sync (all from `ark_core`).
///
/// Values marked TODO depend on the client (藤井先生): product id, what is
/// free, legal URLs and the Firebase project.
class KidsStore {
  KidsStore._();

  /// TODO(client): final product id from App Store Connect / Play Console.
  static const productId = 'com.ark.kids.full_unlock';
  static const entitlement = 'kids_full';

  /// Purchase UI is shown only when this is on (or in debug builds). Off
  /// until the paid question sets exist — today every bundled question is
  /// the free version, so there is nothing to sell yet.
  static const monetizationEnabled = false;
  static bool get showPurchaseUi => monetizationEnabled || kDebugMode;

  /// What is free without buying. TODO(client): e.g.
  /// `ContentAccessRules(freeCounts: {'vocab': 1, 'listening': 2})`, or a
  /// `free` column per question in the Google Sheet.
  static final access = ContentAccess(rules: ContentAccessRules.allFree);

  /// TODO(client): 利用規約 / プライバシーポリシー pages.
  static final Uri? termsUrl = null;
  static final Uri? privacyUrl = null;

  static Future<void> init() async {
    unawaited(PurchaseService.instance.configure(const PurchaseConfig(
      products: [PurchaseProduct(id: productId, entitlements: {entitlement})],
      requiredEntitlement: entitlement,
    )));

    await ArkAuth.instance.init(
      appId: 'kids',
      // TODO(client): DefaultFirebaseOptions.currentPlatform after running
      // `flutterfire configure`. Until then login is hidden and the app
      // plays fully offline.
      firebaseOptions: null,
      sync: ProgressSyncSpec([
        const SyncKey(ProgressKeys.playerName, MergeRule.lastWriteWins),
        const SyncKey(ProgressKeys.friends, MergeRule.union),
        const SyncKey(ProgressKeys.storySeen, MergeRule.lastWriteWins),
        const SyncKey(ProgressKeys.story2Seen, MergeRule.lastWriteWins),
        SyncKey.prefix(ProgressKeys.cards(''), MergeRule.union),
        SyncKey.prefix(ProgressKeys.sRankCount(''), MergeRule.max),
        const SyncKey.prefix('ark_best_', MergeRule.max),
        const SyncKey.prefix('lb2_', MergeRule.max), // listening level bests
        const SyncKey.prefix('eb2_', MergeRule.max), // sentence bests
        // ark_se / ark_voice / ark_bgm stay per device on purpose.
      ]),
    );
    // Progress pulled from the cloud (another device): refresh screens.
    ArkAuth.instance.sync?.onPulled = (_) => ProgressService.instance.notifyExternalChange();
  }

  /// Parent gate → paywall. Returns true when everything is unlocked.
  static Future<bool> openPaywall(BuildContext context) => showPaywall(
        context,
        requireParentGate: true,
        features: const [
          PaywallFeature('🎮', '4つの ゲームの ぜんぶの もんだい'),
          PaywallFeature('🆕', 'ふえていく あたらしい もんだいも あそべる'),
          PaywallFeature('💎', 'いちど かえば ずっと あそべる'),
        ],
        termsUrl: termsUrl,
        privacyUrl: privacyUrl,
        openUrl: (u) => launchUrl(u, mode: LaunchMode.externalApplication),
      );
}
