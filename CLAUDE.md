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

**Hybrid Tiered Memory System** - Prevents token bloat while maintaining context.

### Memory File Structure

```
docs/memory/
├── current.md          # Lightweight (max 100 lines) - ALWAYS loaded
├── weekly/             # Weekly summaries - loaded on demand
│   └── {year}-W{week}.md
└── detailed/           # Full detailed logs - rarely loaded
    └── {year}/{month}/{day}.md
```

---

### 1. Current Memory (`docs/memory/current.md`)

**⚠️ CRITICAL: ALWAYS load `current.md` at session start**

- **Max 100 lines** - strictly enforced
- Contains only last 7 days of work (ultra-compact)
- **Loaded every session** (low token cost ~500 tokens)
- Auto-rotates: entries older than 7 days → archived to weekly summary

#### Format:

```markdown
# Current Session Memory

## Last 7 Days (Auto-Rotated)

### 2025-12-08

- ✅ Fixed auth token interceptor cascade logout
- 📝 Modified: dio_client.dart, auth_cubit.dart

### 2025-12-07

- ✅ Added TikTok URL merchant support
- 📝 Modified: url_resolver.dart

## Active Blockers

- None

## Pending Tasks

- Review PR #137
```

#### Content Rules:

- One date section per day (most recent first)
- Max 5 bullet points per day
- Use icons: ✅ (done), ⏳ (in progress), ❌ (blocked)
- File changes: file names only, NO line numbers
- NO detailed explanations - just facts

---

### 2. Weekly Summary (`docs/memory/weekly/{year}-W{week}.md`)

**Created automatically** when:

- Every Sunday, OR
- When `current.md` exceeds 100 lines

**Load only when**: Investigating work from previous weeks

#### Format:

```markdown
# Week 48 - December 2025

## Major Changes

- Enhanced authentication flow with token refresh fallback
- Added 8 new merchant URL resolvers
- Fixed clipboard caching performance issues

## Key Files Modified

- lib/core/module/dio/dio_client.dart
- lib/features/auth/presentation/cubit/auth_cubit.dart

## Blockers Resolved

- 401 cascade logout issue
```

---

### 3. Detailed Archive (`docs/memory/detailed/{year}/{month}/{day}.md`)

**Full detailed logs** with complete information:

```markdown
### Issue Title

**Status:** ✅ RESOLVED | ⏳ IN PROGRESS | ❌ BLOCKED
**Time:** HH:MM

#### What Was Done

- Detailed implementation description

#### Files Changed

- `path/to/file.dart` (lines X-Y): Description of change

#### Benefit/Impact

- Why this change matters

#### Goal Achieved

- ✅ Acceptance criteria
```

**Load only when**: Deep investigation of specific past work needed

---

### Memory Management Workflow

#### On Session Start:

```
1. Get today's date: date=$(date +"%Y-%m-%d")
2. Load `docs/memory/current.md` (ALWAYS)
3. Check if rotation needed:
   - If oldest entry in current.md > 7 days old, OR
   - If current.md > 100 lines:
     → Run rotation (see below)
4. Check if today's date already in current.md:
   - If YES: append to existing date section
   - If NO: add new date section at top
```

#### Auto-Rotation Process:

```
1. Read current.md
2. Extract entries older than 7 days
3. Group by week
4. Append to appropriate weekly/{year}-W{week}.md
5. Remove old entries from current.md
6. Keep only last 7 days in current.md
```

#### Saving Today's Work:

**Always update TWO files:**

1. **`current.md`** (required) - Add compact entry:

   ```markdown
   ### 2025-12-08

   - ✅ Task completed
   - 📝 Modified: file1.dart, file2.dart
   ```

2. **`detailed/{year}/{month}/{day}.md`** (optional) - Full details if needed

---

### Key Principles

1. **Always load `current.md` first** - never skip this
2. **Keep `current.md` under 100 lines** - ruthlessly compact
3. **Weekly summaries** consolidate past work
4. **Detailed archives** preserve full history
5. **Auto-rotation** prevents bloat
6. **Git history** is primary source of truth for code changes

---

### Migration from Old System

Existing `docs/memory/{year}/{month}/{day}.md` files are now "detailed archive" files. They remain unchanged and accessible when needed.
