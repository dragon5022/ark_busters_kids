import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum GameModeId { vocab, listening, talk, sentence }

class GameMode {
  const GameMode({
    required this.id,
    required this.titleJa,
    required this.titleEn,
    required this.monsterName,
    required this.cardAsset,
    required this.accent,
    required this.accentDeep,
  });

  final GameModeId id;
  final String titleJa;
  final String titleEn;
  final String monsterName;
  final String cardAsset;
  final Color accent;
  final Color accentDeep;
}

const List<GameMode> kGameModes = [
  GameMode(
    id: GameModeId.vocab,
    titleJa: 'ボキャブラリー',
    titleEn: 'Vocabulary',
    monsterName: 'ボキャモン',
    cardAsset: 'assets/images/hub/card-vocab.webp',
    accent: AppColors.purple,
    accentDeep: AppColors.purpleDeep,
  ),
  GameMode(
    id: GameModeId.listening,
    titleJa: 'リスニング',
    titleEn: 'Listening',
    monsterName: 'リスモン',
    cardAsset: 'assets/images/hub/card-listening.webp',
    accent: AppColors.yellow,
    accentDeep: AppColors.yellowDeep,
  ),
  GameMode(
    id: GameModeId.talk,
    titleJa: 'トーク',
    titleEn: 'Talk',
    monsterName: 'トークモン',
    cardAsset: 'assets/images/hub/card-talk.webp',
    accent: AppColors.blue,
    accentDeep: AppColors.blueDeep,
  ),
  GameMode(
    id: GameModeId.sentence,
    titleJa: 'センテンス',
    titleEn: 'Sentence',
    monsterName: 'グラモン',
    cardAsset: 'assets/images/hub/card-sentense.webp',
    accent: AppColors.orange,
    accentDeep: AppColors.orangeDeep,
  ),
];
