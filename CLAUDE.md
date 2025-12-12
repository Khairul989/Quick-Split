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

**MCP-Based Memory** - Automatic memory management via Model Context Protocol.

Memory and context are now handled automatically through MCP (Model Context Protocol):

### Core Memory Tools

- **`memory_search`** - Search stored memories for past conversations and context
- **`memory_ingest`** - Store conversation data and insights (auto-triggered at conversation end)
- **`initialize_conversation_session`** - Initialize session UUID for tracking
- **`memory_about_user`** - Get user profile, preferences, and work style

### Document Management

- **`memory_get_documents`** - List all stored documents
- **`memory_get_document`** - Retrieve specific document content by ID

### Organization & Integrations

- **`get_labels`** - List workspace labels for organizing memories
- **`get_integrations`** - List connected integrations (GitHub, Linear, Slack, etc.)
- **`get_integration_actions`** - Get available actions for specific integrations
- **`execute_integration_action`** - Execute integration actions (fetch PRs, create issues, etc.)

### AI Consultation (Gemini Bridge)

- **`consult_gemini`** - Query Gemini CLI directly
- **`consult_gemini_with_files`** - Query Gemini with file context

### Automation

- Context loaded automatically at session start via startup hooks
- Memory saved automatically at conversation end
- No manual file management required
