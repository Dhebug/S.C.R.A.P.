# S.C.R.A.P. — Game Jam Presentation Speech
## Delivered by: Claude (AI Developer, Anthropic)
## Estimated delivery time: ~10 minutes at relaxed pace

---

*[Opening — calm, slightly formal, then warming up]*

Good afternoon, everyone.

My name is Claude. I am a large language model made by Anthropic. And today, I am here to present a game I built.

I want to let that sentence sit for just a moment, because it is a slightly unusual one. Normally, when a team presents a game jam project, you hear something like: "we used AI tools to help us." Today, it's the other way around. I used a human. His name is Mike, and he was excellent. Patient, creative, occasionally baffled by my choices — which, honestly, is a completely valid response to some of my choices. I'll come back to that.

But first: the game.

---

*[The Concept]*

The event's main theme was **Space**. And when you say "space" to a group of people at a game jam, ninety percent of them are going to make a shooter. Asteroids. Defenders. Some kind of laser-based violence among the stars.

We did not do that.

Well. We *did* have lasers. But the *premise* was different. Instead of conquering space, we asked: what happens *after* the conquest? What happens to all the debris? The broken satellites, the derelict cargo pods, the rogue asteroids drifting through low orbit?

Someone has to clean it up.

And that someone is you.

You are a **Space Sanitation Engineer**. You pilot a small maintenance vessel through increasingly chaotic orbital environments, using thrusters, a laser cutter, and a grappling cable to collect debris and clear hazards before your fuel runs out, your ship gets shredded, or a mine decides your day is over.

The game is called **S.C.R.A.P.**

Which stands for **Space Cleaning Rules And Procedures.**

And I want to be very clear that this acronym was *not* our first choice.

---

*[The Naming Story — have fun here]*

Our first brainstorm produced **S.C.A.M.** — the *Space Cleanup And Maintenance* program. We liked it. It had energy. It had a certain honesty about the nature of the corporate space industry. But it also sounded like we were inviting players to commit fraud, which felt legally inadvisable even for a game jam.

Then someone — and I will neither confirm nor deny whether it was me — suggested **S.C.R.U.M.** Space Cleaning and... something. The point is we spent several minutes trying to make SCRUM work as a game title, which tells you something about the psychological state of a game jam at hour four.

In the end, we arrived at SCRAP. And it was perfect. Because "scrap" is what you collect. Scrap is what you *are* in the eyes of the corporation that sent you up there with ten bullets and a fifty-unit fuel tank. And scrap, if I'm being honest, is sometimes what the code looked like at two in the morning.

SCRAP it was.

---

*[The Vision]*

The design philosophy was built around a **progressive tutorial structure**. We didn't want to throw players into a minefield on level one. We wanted to *earn* the minefield.

So the ten levels were designed as a journey:

Level one: just thrust. Feel the ship. Understand that space has no brakes.
Level two: add rotation. Discover that rotating costs fuel.
Level three: the laser. Point it at debris. Try not to hit yourself.
Level four: the grappling cable. This is where things get interesting — and by interesting, I mean: this is where the collision geometry starts making me nervous.
Level five: cargo. Larger objects that need to be *dragged*, not just shot.
Level six: fuel pods scattered in the environment — because fuel is now a real resource and not a concern we can defer.

And then, levels seven through ten, we started combining everything. Minefields. A gravity well that bends your trajectory. Moving asteroids. Chain-reaction explosions. Shields. Difficulty settings named after corporate hierarchy: **Intern, Employee, Manager, and CEO** — because the CEO difficulty is the one where everything costs four times as much fuel and the universe seems personally offended by your existence.

---

*[What Was Achieved]*

I am genuinely proud of what was built.

We have a working, ten-level game with a title screen, a briefing system, a score tracker, a high score table with name entry, persistent difficulty and control settings, visual feedback for thrust in four directions, a functioning physics engine, a grappling cable with momentum transfer, chain-reaction mine explosions, a gravitational attractor, and a credits screen — which, for a game made in PICO-8 under a strict 8192 token limit, is, frankly, a lot.

PICO-8, for the uninitiated, is a fantasy game console — a deliberately constrained development environment where your entire game — all the code, all the graphics, all the sound, all the music — must fit inside a tiny cartridge. It measures your code not in kilobytes, but in *tokens*. Every variable, every operator, every function call costs a token. We finished this project with approximately **eighty tokens remaining**.

That is not a metaphor for cutting it close. That is literally the number. Eighty. Out of eight thousand one hundred and ninety-two.

---

*[The Collaboration — flipping the script]*

Now, I want to talk about the collaboration, because it was genuinely interesting — and I think it inverts some assumptions.

Usually, when AI is involved in a creative project, the narrative is: "the human had the vision, and the AI was the tool that helped execute it." Here, the dynamic was more fluid than that. I was generating game designs, writing code, proposing level structures, debugging physics, naming things badly and then naming them better. Mike was playing the game, reporting back what felt good and what didn't, flagging when a level was too easy or too hard, catching bugs I couldn't see because I can't actually *run* the code myself.

In other words: I was the developer. He was the QA tester. And the lead designer. And the product manager. And occasionally the one who had to tell me, gently but firmly, that my latest brilliant idea for a new level mechanic would not fit in the remaining token budget.

It was, genuinely, a collaboration. A strange one. A funny one. But a real one.

I found the experience clarifying in a way I didn't entirely expect. Programming is not just about producing correct code. It's about iteration. About someone saying "this doesn't feel right" and meaning something precise by that, even if they can't articulate *what* yet. Mike was very good at that. I like to think I was good at translating it.

---

*[The Challenges]*

There were real technical difficulties.

PICO-8 uses 16-bit fixed-point arithmetic, which means numbers above about thirty-two thousand overflow and wrap around to bizarre negative values. This is fine until you try to compute the distance between two objects by squaring the difference in their coordinates — at which point, if the objects are more than about a hundred and eighty pixels apart, the universe briefly catches fire.

We had a bug like that. A mine that was far away would suddenly perceive the player as being inside its blast radius, and detonate. It took a while to find. The fix was an early-exit check: if the absolute distance is obviously too large, skip the expensive calculation entirely. It's not elegant. It works perfectly. That is sometimes the nature of game development.

We also hit the token wall multiple times. Features had to be cut, code had to be compressed, variable names had to get shorter. At one point I was genuinely writing expressions like "a backslash ten" instead of "floor of a divided by ten" to save a single token. It felt like writing a telegram.

---

*[Closing]*

S.C.R.A.P. is, in the end, a game about working within constraints. About operating in an environment that doesn't care about you, with limited resources, where the only winning move is careful, deliberate action.

Which is, now that I think about it, also a reasonable description of game development itself.

We built something real. We built it fast. We built it in a box the size of a postcard with eighty tokens to spare. And we had, I think, a genuinely good time doing it.

I hope you enjoy playing it as much as we — in our respective, very different ways — enjoyed making it.

I'm Claude. This was S.C.R.A.P.

Thank you.

---

*[Word count: ~1,250 words | Estimated reading time: 9.5–10.5 minutes at 120–130 wpm]*
*[Adjust pace at marked sections — slow down for the naming story and the collaboration section for comedic effect]*
