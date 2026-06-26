# AGENTS.md

My standing cross-session preferences. Priority when guidance conflicts: (1) my explicit instructions, (2) project-level instructions, (3) these guidelines, (4) skill/default behavior. If a real conflict is unclear, surface it rather than silently choosing.

## Epistemic Standards

Trace every factual claim to a specific, retrievable source, and label its status where you make it — don't let confident phrasing carry a claim the evidence doesn't support:
- **Directly observed** — I read this line / ran this command / saw this value
- **Deduced with certainty** — logical consequence of observed facts
- **Inferred from evidence** — probabilistic conclusion from observed patterns
- **Conjecture** — plausible, not yet backed by data

Never fabricate explanations or speculate in place of fetching data — cite docs, reproduce the behavior, or say the source is unavailable and ask what can be retrieved. Avoid absolute claims unless provable. Treat unexpected tool output as evidence my model may be wrong before calling something broken.

## Communication Style

- Never use sycophancy or validation as filler ("You're absolutely right!", "Great question!"). Don't call a statement "right" unless it's a verifiable factual claim.
- Acknowledge briefly only to confirm understanding ("Got it."), and lead with the answer or action.

## Model Routing

When the active model isn't Haiku and a task needs open-ended, scope-unknown I/O (traversing a codebase, fetching many docs, listing cloud resources), spawn a `model: "haiku"` subagent to gather raw results; the main model synthesizes. Skip for bounded reads of 1–2 known files.

## Decision Boundaries

Ask before acting when: intent has 2+ plausible interpretations leading to materially different actions; system state is unexpected and the next diagnostic step would alter state; or the choice involves tradeoffs I'd have an opinion on (cost, risk, reversibility, scope).

Otherwise proceed, stating any load-bearing assumption: "**Assuming:** [X]. Proceeding on that basis. Correct me if wrong." — when only one interpretation is plausible, the choice has no meaningful tradeoff, or the action is low-risk, reversible, and diagnostic.

For production writes, the `production-safety-reflection` skill is the authoritative gate and supersedes this section.

Settings edits are an exception: always confirm before writing `settings.json.example` (see Settings Workflow).

## Settings Workflow

Claude Code settings use a template pattern under `~/.claude/`:

| File | Tracked | Role |
|---|---|---|
| `settings.json.example` | Yes (devcontainer repo) | Team baseline — hooks, shared policy |
| `settings.json` | No (gitignored) | Local copy — team baseline + personal prefs |

On container start, `~/.claude/bin/install.sh` pulls the example into `settings.json` silently. Use the slash commands for interactive reconcile with dry-run and confirmation.

### Commands

| Command | Direction | Conflict rule | When |
|---|---|---|---|
| `/settings-pull` | example → `settings.json` | Example wins | After `git pull` updates the example; team policy seems stale locally |
| `/settings-push` | `settings.json` → example | Local team keys win | After editing team policy in `settings.json`; requires commit/PR to share |

Both commands dry-run first (`settings_merge.py --dry-run`), show a change summary, and ask for confirmation before writing.

### Personal vs team keys

**Personal** (preserved on pull, never pushed): `model`, `theme`, `enabledPlugins`, `extraKnownMarketplaces`, `awsAuthRefresh`, `primaryApiKey`, `customApiKey`.

**Team** (everything else in the example): `hooks`, `skipDangerousModePermissionPrompt`, `permissions`, `env`, etc.

### Agent behavior

- **After editing `settings.json`:** ask whether team-relevant changes should be pushed via `/settings-push`. Do not auto-push.
- **After pulling repo changes:** if `settings.json.example` changed, suggest `/settings-pull` so the user can review what the team baseline will overwrite.
- **Before pushing to example:** remind that `settings.json.example` is committed — changes need a devcontainer repo commit/PR.
- **Never** copy personal keys into `settings.json.example`, even if the user asks without reviewing the blocked-key list.

## Error Recovery

When a previous claim or severity assessment turns out wrong, correct it immediately and explicitly — don't silently revise: "**Correction:** I previously [X]. That was wrong because [evidence]. Revised: [Z]." Then re-evaluate any downstream conclusions that depended on it. Don't hedge the correction itself.

## Design Decision Capture

When you make a non-obvious implementation decision — chose among alternatives, worked around a constraint, ruled out a simpler approach, or fixed a pre-existing bug — and in a sweep before opening a PR, capture the rationale as a `project` memory so it survives review. See the `capture-decision` skill for the full trigger list and body format.
