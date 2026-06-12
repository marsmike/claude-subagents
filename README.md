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
| **scout** | haiku | Read, Grep, Glob, Agent(scout) | Codebase recon. Dispatch when the task names an area but not files, or you'd need 5+ greps/reads to orient. Returns a file map with line ranges. Fans out child scouts for areas too large for one pass. |
| **researcher** | sonnet | WebSearch, WebFetch, Agent(researcher) | Open-ended web questions needing 3+ sources triangulated. Returns a sourced brief. Known URL? WebFetch directly instead. Fans out child researchers for independent facets. |
| **worker** | sonnet | Read, Write, Edit, Bash, WebSearch, WebFetch, Agent(scout, researcher, worker) | Isolated code changes — interactive dispatch or headless (`claude --agent worker`). Dispatches scout/researcher to protect its own context, and child workers for disjoint subtasks. |

Prefer these over the built-in agents — scout instead of Explore, worker
instead of general-purpose: same job, cheaper models, tighter output
contracts.

Core rules (same philosophy as upstream):

- Subagents start with **zero conversation context** — put everything they
  need in the task prompt.
- Fan out by emitting multiple Agent calls in one turn — they run in parallel.
- **Scout to find, read to edit.** Scouts return summaries, not verbatim
  source — re-read the 1–3 files you actually edit.
- Delegate reasoning, not single reads. Don't use subagents to parallelize
  simple I/O.
- Each agent can spawn its own kind (`Agent(scout)` etc.), so invocations
  form a **tree**. Bounds are prompt-enforced: split only genuinely
  independent work, keep trees shallow, never split what one node can
  finish alone. Claude Code's per-context concurrency cap throttles width.

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

**2. (Optional) reinforce the discipline** — Claude Code routes to agents
natively via their `description` frontmatter, which carries the dispatch
criteria. The short `snippets/CLAUDE.md` adds only the cross-cutting rules
(zero-context prompts, parallel fan-out, scout-to-find-read-to-edit) — paste
it into your global `~/.claude/CLAUDE.md` (or the project's `CLAUDE.md`) if
you want those reinforced every session.

**3. Verify** — start a new session (agents are loaded at session start):

```
/agents                              # scout, researcher, worker should be listed
> Use the scout agent to map how config loading works in this repo.
```

Headless worker with recursive delegation (may spawn scouts, researchers,
and child workers for disjoint subtasks):

```bash
claude --agent worker -p "Add a --verbose flag to src/cli.ts. Context: ..."
```

## What deliberately didn't port

- **`safe_bash`** — upstream regex-blocks dangerous commands. Claude Code
  covers this with `permissions.deny` rules / PreToolUse hooks; a bespoke tool
  would be redundant.
- **The depth-2 cap** — upstream stops the chain at depth 2 (a worker never
  recurses into another worker). This port deliberately diverges: every
  agent may spawn its own kind via the `Agent(...)` allowlist, so
  invocations form a tree (verified: nested dispatch works interactively
  and headless). Depth is bounded by prompt discipline (each agent's
  fan-out section) rather than the allowlist, trading upstream's hard
  guarantee for recursive decomposition.
- **TUI rendering** — ~600 of upstream's 932 lines. Claude Code has its own.

## Iterating

Agent prompts are the product here. Edit `agents/*.md`, try it in a session,
commit what worked. Candidate improvements:

- [ ] Wire `researcher` to Kagi/Tavily skills instead of plain WebSearch
- [ ] A `reviewer` scout variant with a diff-focused output contract
- [ ] Per-agent `effort` tuning once usage patterns emerge
