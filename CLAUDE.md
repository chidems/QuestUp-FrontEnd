# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

# Quest Up — Frontend

Flutter mobile app. Pixel-art RPG gamification app for real-world quests.

## Stack
- Flutter 3.x / Dart
- Riverpod (state management)
- GoRouter (navigation)
- Dio (HTTP)
- Flutter Secure Storage (JWT)
- geolocator, image_picker, google_maps_flutter

## Architecture
Feature-first folders under lib/features/. Widget → Provider → Repository → API Client → Dio.

## Key Rules
- Never put API calls directly in widgets.
- Mock mode: `flutter run --dart-define=USE_MOCK_API=true`
- Android emulator backend URL: 10.0.2.2 (not localhost)
- JWT goes in Flutter Secure Storage only, never SharedPreferences.
- No background location tracking in MVP.

## Build Order (Phases)
Phase 1: Foundation (theme, routing, auth, Dio, mock mode)
Phase 2: Quest Feed MVP
Phase 3: Completion + Rewards
Phase 4: Weekly Quest
Phase 5: Avatar + Store
Phase 6: NPC + Walking
Phase 7: Polish

## Current Phase
All MVP phases (1–7) complete. Profile/Stats, Achievements, Quest History, and Settings done.
Remaining: real pixel-art assets, optional backend prefs sync, token refresh, demo polish.

## Full spec
See: claude_frontend_build_prompt.md

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
