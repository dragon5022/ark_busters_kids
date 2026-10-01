/// localStorage-compatible keys from the original web game.
class ProgressKeys {
  static const friends = 'ark_friends';
  static const playerName = 'ark_name';
  static const seEnabled = 'ark_se';
  static const voiceEnabled = 'ark_voice';
  static const storySeen = 'ark_story_seen';
  static const story2Seen = 'ark_story2_seen';

  static const bestVocabulary = 'ark_best_vocabulary';
  static const bestListening = 'ark_best_listening';
  static const bestTalk = 'ark_best_talk';
  static const bestSentence = 'ark_best_sentence';

  static String cards(String monsterKey) => 'ark_cards_$monsterKey';
  static String sRankCount(String monsterKey) => 'ark_s_$monsterKey';
}
