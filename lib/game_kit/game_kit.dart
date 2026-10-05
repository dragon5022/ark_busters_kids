/// Shared UI for the hub and all four games (ported from the web pages).
///
/// - [GameStartLayout], [GradeTabs], [ModeCardButton] — start screens
/// - [ArkBottomNav] — コレクション / プロフィール / せってい bar
/// - [ArkHomeButton], [BgmButton], [GameButton], [QuitButton], [TimerBar]
/// - [showArkConfirm], [showArkNotice] — confirm() / alert()
/// - [ReactionController] + [ReactionLayer], [FeedbackController] +
///   [FeedbackPop], [ConfettiBurst] — battle effects
/// - [showReadyGo], [RankLetter], [ResultImage], [BefriendBanner],
///   [NewCardsReveal] — intro and end screen
library;

export '../widgets/effects.dart';
export '../widgets/pressable.dart';
export 'ark_nav.dart';
export 'ark_ui.dart';
export 'answer_fx.dart';
export 'battle_fx.dart';
export 'game_start_screen.dart';
export 'result_fx.dart';
