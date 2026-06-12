# Subagents

scout / researcher / worker in `~/.claude/agents/` — context-protecting
delegation (routing criteria live in each agent's description). **Prefer
them over built-ins: scout instead of Explore, worker instead of
general-purpose** — same job, cheaper models, tighter output contracts.
Rules: subagents start with ZERO conversation context, so put everything
they need in the task prompt. Fan out with multiple Agent calls in one turn
(parallel). Each agent can spawn its own kind, so big jobs become shallow
invocation trees — split only genuinely independent work; a node that can
finish alone does. **Scout to find, read to edit** — scouts return
summaries, not verbatim source; re-read the 1–3 files you actually edit.
Delegate reasoning, not single reads.
