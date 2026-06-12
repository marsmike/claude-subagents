# claude-subagents

Minimal subagents for Claude Code — a port of
[amosblomqvist/pi-subagents](https://github.com/amosblomqvist/pi-subagents)
(an extension for [pi](https://github.com/badlogic/pi-mono) by Mario Zechner).

The pi original is ~1,300 lines because pi has no subagent engine — it spawns
isolated processes and renders its own TUI. Claude Code ships all of that
natively (`.claude/agents/`, the Agent tool, parallel dispatch), so the port
is just the three system prompts. No code.

## Origin & credits

The idea and the agent prompts come from
[amosblomqvist/pi-subagents](https://github.com/amosblomqvist/pi-subagents):
instead of a heavyweight orchestration framework, register **one tool and
three agents** — a cheap read-only scout, a web researcher, and a worker —
each running in full isolation with zero inherited context, parallelized by
emitting multiple calls in one turn, with recursion bounded at depth 2 (a
worker may spawn scouts/researchers, never another worker). The prompts in
`agents/` are adapted nearly verbatim from that repo; the delegation playbook
("scout to find, read to edit") is its core contribution.

pi-subagents is an extension for [pi](https://github.com/badlogic/pi-mono),
Mario Zechner's deliberately minimal coding agent ([design
notes](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)) — the same
less-is-more philosophy this port tries to keep.

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

## Install (Claude Code)

Subagents are plain markdown files — installing means putting them where
Claude Code scans for agent definitions.

**1. Get the agent files in place** — pick one:

```bash
# a) Symlink (recommended for iterating — repo edits go live immediately)
git clone https://github.com/marsmike/claude-subagents.git
cd claude-subagents && ./install.sh

# b) Copy, user scope (available in every project)
cp agents/*.md ~/.claude/agents/

# c) Copy, project scope (this project only, shareable via git)
cp agents/*.md /path/to/project/.claude/agents/
```

If the same agent name exists in both scopes, the project-level file wins.

**2. Teach the main session when to dispatch** — paste `snippets/CLAUDE.md`
into your global `~/.claude/CLAUDE.md` (or the project's `CLAUDE.md` for
project scope). Without this, the agents exist but Claude rarely reaches
for them unprompted.

**3. Verify** — start a new session (agents are loaded at session start):

```
/agents                              # scout, researcher, worker should be listed
> Use the scout agent to map how config loading works in this repo.
```

Headless worker with bounded recursion (worker may spawn scout/researcher
but no other workers):

```bash
claude --agent worker -p "Add a --verbose flag to src/cli.ts. Context: ..."
```

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
