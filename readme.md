# S.C.R.A.P.
## Space Cleaning Rules And Procedures

A PICO-8 game made for the "Space" Game Jam.

---

### Concept

You want to join the **Space Cleaners**, an agency specialized in cleaning up space: removing annoying asteroids, derelict ships, floating space trash, and more. But first, you must pass your certification.

This game is the official **training simulator** published by **S.C.A.M.** (Space Cleaning Advanced Management) and is targeted at **S.C.U.M.** (Space Cleaners Unlicensed Members) who will learn **S.C.R.A.P.** (Space Cleaning Rules And Procedures).

Pass all the tests to earn your Space Cleaner certification!

### Controls

- **Arrow Up** - Main thruster (forward)
- **Arrow Down** - Retro thruster (brake)
- **Arrow Left** - Left lateral thruster (rotate counter-clockwise)
- **Arrow Right** - Right lateral thruster (rotate clockwise)
- **Button O (Z/C)** - Cycle item/weapon
- **Button X (X/V)** - Use selected item/weapon

Controls are unlocked progressively as you advance through the training levels.

### Ship

Your training vessel is equipped with four thrusters:
- **Main thruster** (rear) - Primary forward propulsion
- **Retro thruster** (front) - Reduces velocity / brakes
- **Left lateral thruster** - Rotates ship clockwise
- **Right lateral thruster** - Rotates ship counter-clockwise

The ship also has two equipment slots for items/weapons, cycled with the O button and activated with X.

### Levels

Each level is a training test with:
- A title and briefing
- Specific unlocked controls
- Success and failure conditions
- A score based on performance (time, fuel used, accuracy)

#### Level 1 - "Straight Ahead"
- **Briefing:** "Navigate from point A to point B in a straight line. Simple, right? S.C.A.M. believes in you. Mostly."
- **Controls:** Forward/backward thrust only
- **Objective:** Reach the landing zone
- **Fail condition:** Run out of fuel or crash

#### Level 2 - "Turn Around"
- **Briefing:** "The landing zone isn't always conveniently in front of you. Time to learn how to turn. Try not to get dizzy."
- **Controls:** All four thrusters
- **Objective:** Reach the landing zone (requires rotation)
- **Fail condition:** Run out of fuel or crash

#### Level 3 - "Clear the Path"
- **Briefing:** "Sometimes the trash is in the way. That's why we gave you a laser. Please don't point it at coworkers."
- **Controls:** All thrusters + Laser weapon
- **Objective:** Destroy the obstacle blocking the path, then reach the landing zone
- **Fail condition:** Run out of fuel, crash, or run out of ammo

#### Level 4 - "Tow the Line"
- **Briefing:** "Not everything is trash. Some things are valuable trash. Use the tow cable to haul debris to the collection zone."
- **Controls:** All thrusters + Laser + Tow cable
- **Objective:** Use tow cable to drag debris to collection zone, clear remaining obstacles with laser, reach landing zone
- **Fail condition:** Run out of fuel, crash, lose the cargo, or run out of ammo

### Difficulty

Selectable from the title screen settings menu.

| Difficulty | Fuel Usage | Score Mult | Description |
|------------|-----------|-----------|-------------|
| Intern | 70% | x1 | Generous fuel budget. Good for learning the ropes. |
| Employee | 150% | x2 | Standard fuel consumption. The daily grind. |
| Manager | 250% | x4 | Fuel burns fast. Every thrust counts. |
| CEO | 400% | x8 | Fuel evaporates. Good luck with your golden parachute. |

Difficulty is shown in the Hall of Fame as **I**, **E**, **M**, or **C**.

### Scoring

Each level awards a score based on:
- Fuel remaining
- Level multiplier

Total score is accumulated across all levels.

### End Screen

After completing (or failing) all levels, the player enters a 3-letter name and is added to the highscore table showing:
- Name
- Total score
- Highest level reached

### Assets

#### Sprites

| ID | Description |
|----|-------------|
| 0 | Up arrow icon |
| 1 | Down arrow icon |
| 2 | Left arrow icon |
| 3 | Right arrow icon |
| 4 | Z key icon (rounded key cap) |
| 5 | X key icon (rounded key cap) |

#### Sound Effects

| ID | Description |
|----|-------------|
| 0 | Bullet hit (obstacle damaged) |
| 1 | Ship explosion (crash/death) |
| 2 | Laser fire |
| 3 | UI click (item cycle, cable toggle, level start) |
| 4 | Obstacle/debris destroyed |
| 5 | Cable detach |
| 6 | Error buzzer (disabled control pressed) |
| 7 | UI confirm bloop (engage controls) |
| 8 | Main thruster whoosh (looping, channel 3) |
| 9 | Lateral thruster whoosh (looping, channel 2) |

### Game Jam Modifiers

The game jam offers optional modifiers for extra points. Here are the ones that apply to S.C.R.A.P.:

- **Hipster** - Don't use either of the Big Two game engines (Unreal and Unity). *We use PICO-8.*
- **Hipster++** - Or Godot. *Still PICO-8.*
- **Old School** - Use 8-bit graphics. *PICO-8 is a fantasy console with 128x128 resolution and 16 colors.*
- **Optimized** - Max polycount per model is 256 tris, and max texture size is 256x256 pixels. *PICO-8's spritesheet is 128x128 pixels. No polygons here.*
- **Slop It Up** - ALL code is written by AI, but not cleaned up. *Code generated by Claude, not restructured by the human.*
- **Oldest School** - Use ASCII graphics. *The intro screen features an ASCII art logo.*

#### Could potentially claim

- **I Have No Words** - No text, even UI. *We have briefings and UI text everywhere... but could be reworked.*
- **I Like Poetry** - ALL text rhymes, even UI. *Could be fun but would require rewriting everything.*
- **Monochrome** - Only use two colors/values. *We use multiple PICO-8 colors, but could restrict the palette.*
- **Mouth Sounds** - All audio is made by the human body. *PICO-8 chip sounds, but could replace them.*
- **All You Need Is One** - Playable with only one button. *Level 1 almost qualifies, but later levels need more.*
- **Idle Thumbs** - The game plays itself. *You have to fly the ship... unless we add autopilot.*

#### Incompatible

- **Butlerian Jihad** - No use of generative AI. *Claude helped build this game.*
- **Look Mom No Computer** - Make an analog game. *This is a PICO-8 cartridge.*
- **New School** - All graphics are emoji. *Not on PICO-8.*
- **Handcrafted** - All graphics are hand drawn on paper. *Pixel art, not paper.*
- **Photobash** - All graphics are made from photos you take yourself. *Not on PICO-8.*
- **Back To The Roots** - Based on an old Funcom game. *Not applicable.*
- **Not Again...** - The game is set in a desert. *It's set in space.*
- **It Belongs In A Museum** - Use public domain artwork. *Original pixel art.*
- **Y2K** - Use 2000's futurism art style. *More retro than that.*
- **All Hands On Deck** - Two or more players share a controller. *Single player.*

---

*Copyright 2126 S.C.A.M. - Space Cleaning Advanced Management*
*"Making space cleaner, one unlicensed trainee at a time."*
