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

### Scoring

Each level awards a score based on:
- Fuel remaining
- Time taken
- Bonus objectives (TBD)

Total score is accumulated across all levels.

### End Screen

After completing (or failing) all levels, the player enters a 3-letter name and is added to the highscore table showing:
- Name
- Total score
- Highest level reached

---

*Copyright 2126 S.C.A.M. - Space Cleaning Advanced Management*
*"Making space cleaner, one unlicensed trainee at a time."*
