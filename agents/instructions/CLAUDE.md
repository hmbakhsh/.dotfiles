When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

Use simple, plain language. Domain-specific terms are encouraged when they are the precise word, but avoid verbose jargon and buzzwords that add no meaning. Prefer the shortest word that says the thing exactly.

## Hidden user-invocable skills

Many skills in `~/.claude/skills/` (the Matt Pocock engineering set: to-tickets, to-spec, triage, wayfinder, implement, grill-me, handoff, …) set `disable-model-invocation: true`, so they do NOT appear in your available-skills list. When I mention a `/<name>` anywhere in a message — even mid-sentence after a URL — do not conclude it doesn't exist. Check `~/.claude/skills/<name>/SKILL.md` first, read it, and follow it.
