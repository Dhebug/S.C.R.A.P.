# S.C.R.A.P.
## Space Cleaning Rules And Procedures

A PICO-8 game built entirely by AI for the Funcom Game Jam 2026.

**[Play S.C.R.A.P. in your browser](https://dhebug.github.io/SCRAP/exported/scrap.html)**

---

## About the Project

S.C.R.A.P. was created during the **Funcom Game Jam**, a weekend event organized by Funcom employees from Friday March 6th to Sunday March 8th, 2026. The theme was **Space**.

**99% of everything in this repository is AI-generated.** The game code, the level design, the sound effects, the documentation, even this README and the presentation speech — all written by Claude (Anthropic's AI). The human's role (Mike) was to act as tester, feedback provider, product manager, and the one who had to actually run the game since the AI can't.

The game was built by **Claude Opus 4.6** via Claude Code over the course of the jam weekend. The presentation speech was later written by **Claude Sonnet 4.6**, who didn't realize it was a different model taking credit for someone else's work. [That's a story in itself.](documentation/mistaken_identity.md)

### The Tech

- **Engine:** [PICO-8](https://www.lexaloffle.com/pico-8.php) — a fantasy console with a 128x128 pixel display, 16 colors, and a strict 8,192 token limit for code
- **Final token count:** ~8,112 out of 8,192 (80 tokens to spare)
- **AI tool:** Claude Code (Opus 4.6 for development, Sonnet 4.6 for presentation)

## The Game

You are a **Space Sanitation Engineer** in training. You pilot a small maintenance vessel through increasingly chaotic orbital environments, using thrusters, a laser cutter, and a grappling cable to collect debris and clear hazards.

The game is the official training simulator published by **S.C.A.M.** (Space Cleaning Advanced Management), targeted at **S.C.U.M.** (Space Cleaners Unlicensed Members) who must learn **S.C.R.A.P.** (Space Cleaning Rules And Procedures).

Pass all 10 tests to earn your Space Cleaner certification!

### Controls

| Input | Action |
|-------|--------|
| Arrow Up | Main thruster (forward) |
| Arrow Down | Retro thruster (brake) |
| Arrow Left/Right | Lateral thrusters (rotate) |
| O (Z/C) | Cycle item/weapon |
| X (X/V) | Use selected item/weapon |

Controls are unlocked progressively as you advance through the training levels.

### Difficulty Settings

| Difficulty | Fuel Usage | Score Multiplier |
|------------|-----------|-----------------|
| Intern | 70% | x1 |
| Employee | 150% | x2 |
| Manager | 250% | x4 |
| CEO | 400% | x8 |

### Levels

The 10 levels are a progressive tutorial, each introducing new mechanics:

1. **Straight Ahead** — Thrust only
2. **Turn Around** — Rotation
3. **Clear the Path** — Laser
4. **Tow the Line** — Grappling cable
5. **Bulk Order** — Multi-cargo collection
6. **The Long Haul** — Fuel pod management
7. **Minefield** — Chain-reaction mines, shields
8. **Gravity Assist** — Gravity well, orbiting obstacles
9. **Moving Day** — Moving asteroids, resource pickups
10. **Final Exam** — Everything combined

### Game Jam Modifiers

S.C.R.A.P. qualifies for the following jam modifiers:

- **Hipster / Hipster++** — Not Unreal, not Unity, not Godot. It's PICO-8.
- **Old School** — 8-bit graphics on a 128x128 fantasy console.
- **Optimized** — The entire spritesheet is 128x128 pixels. No polygons.
- **Slop It Up** — ALL code is written by AI, not cleaned up by the human.
- **Oldest School** — The intro screen features an ASCII art logo.

## Documentation

- [Game Manual](documentation/game_manual.md) — Full game details: controls, levels, sprites, sound effects
- [Presentation Speech](documentation/presentation_speech.md) — The 10-minute game jam presentation, written by Claude Sonnet 4.6
- [The Mistaken Identity Incident](documentation/mistaken_identity.md) — What happens when one AI model presents another's work
- [Session Log](documentation/session_log.md) — Full development session transcript

## Running Locally

1. Install [PICO-8](https://www.lexaloffle.com/pico-8.php)
2. Open `scrap.p8` in PICO-8
3. Press Ctrl+R to run

Or open `exported/scrap.html` in any browser to play the web export.

---

*Copyright 2126 S.C.A.M. — Space Cleaning Advanced Management*
*"Making space cleaner, one unlicensed trainee at a time."*
