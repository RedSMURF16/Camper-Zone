<h1 align="center">Camper Zone</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=3Y6oGRHNtb0"><img src="https://img.youtube.com/vi/3Y6oGRHNtb0/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds fully dynamic camper zones to Counter-Strike 1.6.
Camper zones can be placed, managed and configured during gameplay with full runtime control over warnings, damage behavior, team restrictions and activation states.
Custom setups are saved per map and automatically loaded on every map start.
- Create and remove camper zones during gameplay via an in-game menu
- Fully customizable warning and damage system with configurable delays, cooldowns and scaling damage
- Players can receive warning messages, warning slaps, damage or damage slaps while remaining inside a zone
- Configurable per zone: team restriction, warning behavior, damage values, reset delay and damage multiplier
- Delayed and timed activation with random ranges for round-based gameplay
- Intuitive ghost preview with real-time resizing for accurate placement
- [color=red]Requires AMX Mod X 1.9.0+[/color]

## 💬 Commands
- `say /cz` - Opens the Camper Zone menu.
- `say_team /cz` - Opens the Camper Zone menu.
- `cz_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-camper zone settings (defined under each [Camper Zone Name] section):
# CAMPER_FLAGS                      = a - Active Delay, b - Active Duration, c - Warning Slap, d - Warning Message, e - Damage Slap
# CAMPER_TEAM                       = 0 - None, 1 - Terrorist, 2 - Counter-Terrorist, 3 - Both
# CAMPER_DAMAGE                     = Damage dealt per tick
# CAMPER_DAMAGE_TICK                = Delay between each damage tick
# CAMPER_DAMAGE_DELAY               = Delay before damage starts
# CAMPER_DAMAGE_RESET_DELAY         = Delay before the damage timer resets
# CAMPER_DAMAGE_MULTIPLIER_DELAY    = Delay before damage scaling begins
# CAMPER_DAMAGE_MULTIPLIER          = Damage multiplier added over time
# CAMPER_WARNING_DELAY              = Delay before warning starts
# CAMPER_WARNING_COOLDOWN           = Delay before warnings can be repeated
# CAMPER_WARNING_MESSAGE            = Warning message displayed to players
# CAMPER_ACTIVE_CHANCE              = Activation probability (0.0 - 1.0)
# CAMPER_ACTIVE_DELAY               = Activation delay after round start
# CAMPER_ACTIVE_DURATION            = Active duration
# CAMPER_ACTIVE_COOLDOWN            = Cooldown before reactivation
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=3Y6oGRHNtb0)
