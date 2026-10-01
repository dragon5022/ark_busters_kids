# ARK BUSTERS KIDS (Flutter)

English learning game for elementary students — Flutter port of the web ARK BUSTERS KIDS game.

**Detailed requirements:** [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)  
**Content updates (no re-submit):** [docs/CONTENT_UPDATE.md](docs/CONTENT_UPDATE.md)

## Run

```bash
cd ark_busters_kids
flutter pub get
flutter run -d emulator-5554
```

Set JAVA_HOME if needed:

```powershell
$env:JAVA_HOME = "C:\src\jdk-17"
$env:Path = "C:\src\jdk-17\bin;C:\src\flutter\bin;$env:Path"
```

## Structure

```
lib/
  main.dart
  core/theme/          # colors, theme (from web CSS)
  core/constants/      # 4 game modes
  core/progress/       # localStorage key names
  screens/hub/         # top hub (working)
  screens/common/      # placeholders for each mode
  screens/vocab|listening|talk|sentence/  # next
  services/            # audio, progress (next)
assets/
  images/hub/          # mode cards from web
  data/                # JSON question packs (next: export from HTML)
```

## Next steps

1. Export vocab / listening / talk / sentence questions from HTML → `assets/data/`
2. Implement Vocabulary battle screen first
3. Shared progress (`shared_preferences`) + SFX (`audioplayers`)
4. Listening → Sentence → Talk
