---
name: eval-commits
description: Amend commits that don't follow conventional commits format. Analyzes diffs with Haiku and rewrites messages. Use when asked to run /eval-commits or fix commit messages.
---

# Eval-Commits: Conventional Commit Fixer

Rewrites non-conventional commit messages in the current branch using Haiku to analyze each diff.

## Phase 1: Identify scope

Determine the commit range:
- Default: `git log --oneline origin/main..HEAD` (unpushed commits only)
- If the user provided an argument (e.g., `HEAD~5`, a branch name, or a tag), use that as the range base instead

Run the appropriate `git log` command and collect the list of commits (hash + message).

Check each message against the conventional commits pattern:
```
^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?: .+
```

If all commits already conform, report that and stop — no rewriting needed.

## Phase 2: Analyze non-conforming commits (Haiku)

For each non-conforming commit:

1. Run `git show <hash> --stat --patch` to get the full diff
2. Spawn a **Haiku** model Agent with this exact prompt:

```
You are a commit message analyzer. Given a git diff and original commit message, return a conventional commit message.

Original message: <original message here>

Diff:
<diff content here>

Return ONLY a JSON object with these fields:
{
  "type": "feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert",
  "scope": "optional-scope or null",
  "description": "concise lowercase imperative description under 72 chars",
  "breaking": false
}

Rules:
- feat: new capability added
- fix: bug corrected
- docs/chore/style/refactor/test/perf/ci/build: use judgment
- breaking: true only if the change removes or incompatibly alters existing behavior
- description: lowercase, imperative mood, no period at end
```

3. Parse the JSON output and build the full conventional message:
   - With scope: `type(scope): description`
   - Without scope: `type: description`
   - Breaking: append `!` after type/scope, e.g. `feat!: description`

## Phase 3: Present and confirm

Display a table of proposed changes:

```
HASH     OLD MESSAGE                    →  NEW MESSAGE
abc1234  "update stuff"                 →  "chore: update dependency versions"
def5678  "added user login"             →  "feat(auth): add user login flow"
```

Ask the user to confirm before rewriting. If they decline, exit without changes.

## Phase 4: Rewrite history

**Only proceed if user confirmed in Phase 3.**

First, verify no commits in the range have been pushed (if they have, warn the user that rewriting pushed commits requires a force push and ask again before proceeding).

Write a temp mapping file and filter script:

```bash
# Write /tmp/nnai-commit-map.txt with lines: "<hash> <new message>"
# Write /tmp/nnai-msg-filter.sh:
#!/bin/bash
HASH=$(git log --format='%H' -n 1 "$GIT_COMMIT" 2>/dev/null || echo "")
if grep -q "^$HASH " /tmp/nnai-commit-map.txt 2>/dev/null; then
  grep "^$HASH " /tmp/nnai-commit-map.txt | cut -d' ' -f2-
else
  cat
fi

# Make executable
chmod +x /tmp/nnai-msg-filter.sh

# Run filter-branch
git filter-branch --force --msg-filter '/tmp/nnai-msg-filter.sh' <range>

# Clean up
rm -f /tmp/nnai-commit-map.txt /tmp/nnai-msg-filter.sh
```

After rewriting, run `git log --oneline <range>` and show the updated commit list so the user can verify.
