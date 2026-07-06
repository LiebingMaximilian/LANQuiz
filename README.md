# LANQuiz

Multiplayer-Quiz im lokalen Netzwerk. Ein Gerät ist **Host** und verteilt Fragen an alle Mitspieler im selben WLAN/LAN. Die Spiellogik läuft lokal auf dem Host; die Fragen kommen von der [OpenTDB-API](https://opentdb.com).

*Hochschulprojekt ZAPP SoSe 2026 — Severin Köberl, Maximilian Liebing, Julian Müller.*

## Features

- Host/Client-Multiplayer über LAN (kein eigenes Backend)
- Auto-Discovery per mDNS (`bonsoir`) oder manuelle IP-Eingabe
- Konfigurierbar: Runden, Zeitlimit, Kategorie
- Synchroner Timer, animiertes Leaderboard, finales Podest
- Joker: 50:50, Double Down, Ink-Splash, CopyCat
- Spielerverwaltung (Kick) und persistente Statistiken

## Tech-Stack

Flutter/Dart · `provider` (State) · `shelf` + `web_socket_channel` (WebSockets, Port 8080) · `bonsoir` (mDNS) · `http` (OpenTDB) · `shared_preferences` (Persistenz).

Der Host ist Server und Spieler zugleich (`HostGameState extends ClientGameState`); die Kommunikation läuft über typisierte JSON-Pakete (`PacketType`).

## Erste Schritte

Alle Geräte im selben WLAN/LAN; der Host benötigt Internet für die Fragen.

```bash
flutter pub get
flutter run
```

## Credits

Fragen von der [Open Trivia Database](https://opentdb.com) (CC BY-SA 4.0).
