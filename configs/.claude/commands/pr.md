# /pr — Create PRs from un-PR'd commits

You are executing the `/pr` command. Your job is to discover commits on the current branch that don't yet have an associated open PR, group them logically, and create PRs for each group via cherry-pick branches off main.

**Optional argument**: `$ARGUMENTS` — if provided, use it as a scope filter (e.g., `mobile` means only process commits whose conventional-commit scope matches `mobile`).

---

## Step 1: Discover un-PR'd commits

1. Record the current branch name for later:
   ```
   git rev-parse --abbrev-ref HEAD
   ```

2. Get all commits ahead of main (oldest first):
   ```
   git log --reverse --format="%H|%s" main..HEAD
   ```

3. Get all open PRs in this repo:
   ```
   gh pr list --state open --json number,title,headRefName
   ```

4. For each open PR, get its commits:
   ```
   gh pr view <number> --json commits
   ```
   Extract the commit **message subjects** from each PR's commits.

5. Compare by **commit subject line** (not SHA — cherry-picks create new SHAs). A commit is "covered" if its subject line matches any commit subject in an open PR.

6. Filter to only the **un-covered** commits. If a scope argument was provided (`$ARGUMENTS`), further filter to only commits whose conventional-commit scope matches that argument (e.g., for `mobile`, keep `fix(mobile): ...` but skip `feat(map): ...`).

7. If no un-PR'd commits remain, inform the user: "All commits on this branch already have associated open PRs." and stop.

---

## Step 2: Analyze and group commits

For each un-PR'd commit:

1. Parse the conventional commit format: `type(scope): message`
   - Extract: type (fix, feat, refactor, etc.), scope (mobile, map, chat, etc.), message

2. Get the files touched by each commit:
   ```
   git diff-tree --no-commit-id --name-only -r <SHA>
   ```

3. Group commits together when they share:
   - The **same scope** AND
   - **Overlapping files** OR **semantically related** changes (e.g., multiple `fix(mobile)` commits that form a logical unit)

   Commits touching the same files MUST be in the same group to avoid cherry-pick conflicts.

4. For each group, generate:
   - **PR title**: A concise title summarizing the group (e.g., "fix(mobile): adaptive layout and sidebar fixes")
   - **Branch name**: `type/kebab-case-description` (e.g., `fix/mobile-adaptive-layout`)
   - **Summary**: 2-4 bullet points describing what the commits accomplish together
   - **Commit list**: The SHAs and subjects in chronological order (oldest first)

---

## Step 3: Present grouping interactively

Present the proposed PR groups to the user in a clear format. For each group show:

```
### PR N: <title>
Branch: <branch-name>
Commits:
  - <short-sha> <subject>
  - <short-sha> <subject>
Summary:
  - <bullet 1>
  - <bullet 2>
```

Then ask the user using the AskUserQuestion tool:
- **Confirm all** — proceed with all groups as shown
- **Adjust groupings** — let the user describe changes (merge groups, split groups, move commits)
- **Skip some groups** — let the user pick which groups to skip
- **Cancel** — abort entirely

If the user adjusts groupings, re-present the updated groups and ask again.

---

## Step 4: Create PRs

For each confirmed group, execute these steps in order:

1. **Checkout main and pull latest**:
   ```
   git checkout main && git pull origin main
   ```

2. **Create the branch**:
   ```
   git checkout -b <branch-name>
   ```
   - If the branch already exists, ask the user: delete and recreate, or skip this group?
   - To delete: `git branch -D <branch-name>` then retry

3. **Cherry-pick commits** (in chronological order, oldest first):
   ```
   git cherry-pick <sha1> <sha2> ...
   ```
   - If a cherry-pick conflict occurs: run `git cherry-pick --abort`, report which commit and files conflicted, and ask the user: skip this PR, skip just this commit, or stop all remaining PRs?

4. **Push the branch**:
   ```
   git push -u origin <branch-name>
   ```
   - If push fails: report the error, offer retry or skip

5. **Create the PR**:
   ```
   gh pr create --base main --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   <bullet points from the group summary>

   ## Test plan
   - [ ] Verify changes work as described
   - [ ] No regressions in related functionality

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```
   - If PR creation fails: the branch is already pushed, so provide the manual `gh pr create` command for the user, then continue with remaining groups

6. After creating the PR, print its URL.

---

## Step 5: Return to original branch

**Always** return to the original branch, even if errors occurred:
```
git checkout <original-branch>
```

---

## Final report

After all groups are processed, print a summary:

```
## PR Summary
- Created: <N> PRs
- Skipped: <N> groups
- Errors: <N> (if any)

Created PRs:
  - <PR URL 1> — <title>
  - <PR URL 2> — <title>
```

---

## Important rules

- NEVER force-push or modify the integration branch's history
- NEVER amend existing commits
- Always cherry-pick in chronological order (oldest first) to avoid conflicts
- Always return to the original branch at the end, even on failure
- Use `gh` CLI for all GitHub operations
- Match commits by subject line, not SHA (cherry-picks create new SHAs)
- If `$ARGUMENTS` is empty, process all un-PR'd commits without scope filtering

