# Subagents

scout / researcher / worker in `~/.claude/agents/` — context-protecting
delegation (routing criteria live in each agent's description). Rules:
subagents start with ZERO conversation context, so put everything they need
in the task prompt. Fan out with multiple Agent calls in one turn (parallel).
**Scout to find, read to edit** — scouts return summaries, not verbatim
source; re-read the 1–3 files you actually edit. Delegate reasoning, not
single reads.
