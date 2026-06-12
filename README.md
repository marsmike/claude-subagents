# claude-subagents

Minimal subagents for Claude Code — a port of
[amosblomqvist/pi-subagents](https://github.com/amosblomqvist/pi-subagents)
(an extension for [pi](https://github.com/badlogic/pi-mono) by Mario Zechner).

The pi original is ~1,300 lines because pi has no subagent engine — it spawns
isolated processes and renders its own TUI. Claude Code ships all of that
natively (`.claude/agents/`, the Agent tool, parallel dispatch), so the port
is just the three system prompts. No code.

## Agents

| Agent | Model | Tools | When to use |
|-------|-------|-------|-------------|
| **scout** | haiku | Read, Grep, Glob | Codebase recon. Dispatch when the task names an area but not files, or you'd need 5+ greps/reads to orient. Returns a file map with line ranges. |
| **researcher** | sonnet | WebSearch, WebFetch | Open-ended web questions needing 3+ sources triangulated. Returns a sourced brief. Known URL? WebFetch directly instead. |
| **worker** | sonnet | Read, Write, Edit, Bash, WebSearch, WebFetch, Agent(scout, researcher) | Isolated code changes, mainly headless (`claude --agent worker`). Can dispatch scout/researcher to protect its own context — depth capped at 2 by the `Agent(...)` allowlist. |

Core rules (same philosophy as upstream):

- Subagents start with **zero conversation context** — put everything they
  need in the task prompt.
- Fan out by emitting multiple Agent calls in one turn — they run in parallel.
- **Scout to find, read to edit.** Scouts return summaries, not verbatim
  source — re-read the 1–3 files you actually edit.
- Delegate reasoning, not single reads. Don't use subagents to parallelize
  simple I/O.

## Install

```bash
./install.sh        # symlinks agents/*.md into ~/.claude/agents/
```

Symlinks (not copies) so edits in this repo go live immediately — that's the
iterate loop. Then paste `snippets/CLAUDE.md` into your global
`~/.claude/CLAUDE.md` so the main session knows when to dispatch.

## What deliberately didn't port

- **`safe_bash`** — upstream regex-blocks dangerous commands. Claude Code
  covers this with `permissions.deny` rules / PreToolUse hooks; a bespoke tool
  would be redundant.
- **Nested workers** — Claude Code subagents can't spawn subagents in
  interactive sessions. Doesn't matter: interactively, the *main session* is
  the worker (it has edit tools + the Agent tool). The `worker` agent exists
  for headless `claude --agent worker` runs, where the `Agent(scout,
  researcher)` allowlist gives the same bounded recursion as upstream's
  `subagent_agents` frontmatter.
- **TUI rendering** — ~600 of upstream's 932 lines. Claude Code has its own.

## Iterating

Agent prompts are the product here. Edit `agents/*.md`, try it in a session,
commit what worked. Candidate improvements:

- [ ] Wire `researcher` to Kagi/Tavily skills instead of plain WebSearch
- [ ] A `reviewer` scout variant with a diff-focused output contract
- [ ] Per-agent `effort` tuning once usage patterns emerge
