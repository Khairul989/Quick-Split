# CLAUDE.md (Project Level)

This project uses multi-agent orchestration.

The orchestrator agent must follow the global `.claude/CLAUDE.md` for behavior, workflow, permissions, and execution rules.

All project-specific architecture, commands, folder structures, state management rules, and guidelines are defined in `PROJECT_GUIDELINES.md`.

Specialized agents may reference `PROJECT_GUIDELINES.md` for technical details when writing or modifying code.

Do not override global orchestrator behavior.
Do not write code in this file.

---

## Git Commit Rules

**⚠️ CRITICAL: NEVER COMMIT WITHOUT EXPLICIT USER INSTRUCTION**

- **Do NOT run `git commit`** unless the user explicitly asks you to
- **Do NOT run `git push`** under any circumstances without explicit user instruction
- **Do NOT run `git rebase`, `git reset --hard`, or other destructive git commands**
- Only use git for: `git status`, `git diff`, `git log` (read-only operations)
- If user wants a commit, they will explicitly say "commit" or "create a commit"
- Wait for user approval before any git write operations

---

## Memory System

**Event-Driven Memory** - Saves complete, verified work at natural milestones.

### File Structure

```
docs/memory/
├── current.md          # Active session work only
└── detailed/           # Archived sessions
    └── {year}/{month}/
        └── {date}_{time}.md    # e.g., 2025-12-10_1430.md
```

---

### Triggers (When to Save Memory)

**1. Task Completion** (Primary - User-confirmed)

- User confirms: "working", "looks good", "perfect", "verified"
- Agent asks: "✅ Task complete. Update memory?"

**2. Token Usage** (Automatic - Silent)

- When context > 100,000 tokens → Auto-save immediately
- Agent: "💾 Context reached 100k tokens. Saved to memory."

**3. Manual** (User-initiated anytime)

- User: "save memory" / "update memory"
- Agent: Prompts for brief summary, then saves

---

### Commands

**`load memory`**

- Reads `docs/memory/current.md`
- Shows active session work
- Must be called at start of every new session

**`save memory` or `update memory`**

- Archives current session to detailed/{date}\_{time}.md
- Clears current.md for fresh session
- User provides brief summary of work completed

---

### Memory Entry Format

**current.md** (active session):

```markdown
# Current Session

**Session:** 2025-12-10_1430
**Started:** 14:30

## Work in Progress

- ⏳ Fixing OCR multi-line extraction
- 📝 Modified: receipt_parser.dart

## Completed This Session

- ✅ Added dark mode toggle
- 📝 Modified: theme_provider.dart, settings_screen.dart

## Blockers

- None
```

**detailed/{date}\_{time}.md** (archived):

```markdown
# Session 2025-12-10_1430

**Duration:** 14:30 - 16:45
**Status:** ✅ COMPLETE

## Tasks Completed

1. ✅ Fixed OCR multi-line item extraction

   - Modified: receipt_parser.dart (added block/line tracking)
   - Modified: ocr_providers.dart (debug logging)
   - Verified: Tested with 3 receipts, all parsing correctly

2. ✅ Added dark mode with Hive persistence
   - Created: theme_provider.dart, settings_screen.dart
   - Modified: main.dart (theme integration)
   - Verified: flutter analyze 0 errors, persistence working

## User Confirmation

"Tested both features - OCR accurate, dark mode switching smoothly"
```

---

### Content Rules

**current.md:**

- Session ID format: `{date}_{time24h}` (e.g., 2025-12-10_1430)
- Compact bullets only (✅/⏳/❌ + task + files)
- No detailed explanations
- Max ~80 lines (soft limit)

**detailed archives:**

- Full context preserved
- Include user confirmations/test results
- File paths with brief change description
- Status tags (✅/⏳/❌)

---

### Workflow

**On `load memory`:**

1. Read `docs/memory/current.md`
2. Display active session work
3. Check token usage (warn if > 100k)

**On task completion:**

1. User confirms work is done/verified
2. Agent asks: "Update memory?"
3. If yes → save to detailed archive + clear current.md

**On > 100k tokens:**

1. Auto-save current.md → detailed/{date}\_{time}.md
2. Clear current.md
3. Notify user: "💾 Saved to memory (100k token limit)"

---

### Key Principles

1. **Load current.md every session** - never skip
2. **Save at task milestones** - not arbitrary times
3. **Auto-save at 100k tokens** - prevents quality degradation
4. **Detailed archives preserve everything** - git history is secondary
5. **current.md = active work only** - always fresh context
