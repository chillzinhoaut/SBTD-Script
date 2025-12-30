# 🧽 Spongebob Tower Defense Script

Multi-modulares Roblox Script für Spongebob Tower Defense mit WindUI.

## 🚀 Installation

Führe diesen Code in **Codex Executor** aus:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chillzinhoaut/SBTD-Script/main/main.lua"))()
```

## ✨ Features

- ✅ **Auto-Claim Daily Rewards** (1-9) im Loop
- ✅ **Silent Reward System** - Keine Popups oder Animationen
- ✅ **Multi-Modular System** - Module werden von GitHub geladen
- ✅ **WindUI Interface** - Moderne und übersichtliche UI

## 📦 Module

- **reward_claimer.lua** - Automatisches Claimen von Daily Rewards

## 🔄 Updates sofort verfügbar machen

GitHub cached Raw-Dateien für 5 Minuten. Um Updates **sofort** verfügbar zu machen:

### Methode 1: Version erhöhen (Empfohlen)

1. Öffne `main.lua`
2. Ändere die Version in Zeile 25:
   ```lua
   Version = "1.0.2",  -- Von 1.0.1 auf 1.0.2 erhöhen
   ```
3. Commit & Push

**URLs werden dann:**
- `https://raw.githubusercontent.com/.../main.lua?v=1.0.2`
- `https://raw.githubusercontent.com/.../reward_claimer.lua?v=1.0.2`

### Methode 2: jsDelivr CDN (Alternative)

Verwende statt raw.githubusercontent.com:
```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/chillzinhoaut/SBTD-Script@main/main.lua"))()
```

**Vorteile:**
- Schnelleres CDN
- Purge-Cache möglich mit: `https://purge.jsdelivr.net/gh/chillzinhoaut/SBTD-Script@main/main.lua`

## 📁 Projekt-Struktur

```
SBTD-Script/
├── main.lua                    # Master Script mit Module Loader
├── modules/
│   └── reward_claimer.lua      # Auto-Claim Modul
└── README.md
```

## 🛠️ Entwicklung

### Neues Update pushen

```bash
# Änderungen machen
git add .
git commit -m "Update: Beschreibung"
git push

# Version in main.lua erhöhen für sofortiges Update!
```

### Neues Modul hinzufügen

1. Erstelle `modules/dein_modul.lua`
2. Implementiere die `:Init(window)` Funktion
3. Füge in `main.lua` hinzu:
   ```lua
   Modules.DeinModul = LoadModule("dein_modul")
   if Modules.DeinModul then
       Modules.DeinModul:Init(Window)
   end
   ```

## 🔒 Sicherheit

- Keine vertraulichen Daten im Code
- Alle Module werden von GitHub geladen
- Open Source - Code ist einsehbar

## 📝 Lizenz

Dieses Projekt ist für private Nutzung bestimmt.

---

**Erstellt mit [Claude Code](https://claude.com/claude-code) 🤖**
