# Subagents (pi-subagents port)

Three minimal agents in `~/.claude/agents/` for context-protecting delegation.
Subagents start with ZERO conversation context — put everything they need in the
task prompt. Fan out by emitting multiple Agent calls in one turn (parallel).

| Agent | Model | When to use |
|-------|-------|-------------|
| **scout** | haiku | Codebase recon. Dispatch when the task names an area but not files, or you'd need 5+ greps/reads to orient. Returns file map with line ranges. |
| **researcher** | sonnet | Open-ended web questions needing 3+ sources triangulated. Returns a sourced brief. Known URL? WebFetch directly instead. |
| **worker** | sonnet | Isolated code changes, mainly headless (`claude --agent worker`). Can itself dispatch scout/researcher (depth capped at 2). Interactively, the main session plays this role. |

Discipline: **scout to find, read to edit.** Scouts return summaries, not verbatim
source — re-read the 1–3 files you actually edit. Don't use subagents to
parallelize simple I/O; delegate reasoning, not single reads.
