---
name: new-worktree
description: Create a git worktree with a full tmux dev environment (2x2 layout)
user_invocable: true
arguments:
  - name: args
    description: "Worktree name and optional source directory, e.g. 'fix-auth-bug' or 'fix-auth-bug /path/to/repo'"
---

# /new-worktree

Create a git worktree with a full tmux dev environment.

## Instructions

When the user invokes `/new-worktree`, run the worktree setup script.

### Parse arguments

Extract from the user's input:
- **name** (required): The worktree/branch name (first positional argument)
- **source-dir** (optional): The source repo directory (second positional argument, defaults to current working directory)
- **--dry-run** (optional): If user says "dry run" or "preview", add the `--dry-run` flag

### Execute

Run the script via Bash:

```bash
bash .claude/scripts/new-worktree.sh <name> [source-dir] [--dry-run]
```

If the user provides `.` as the directory, resolve it to the current working directory before passing it.

### After execution

Report back to the user:
- The worktree path that was created
- The dev server port
- How to attach to the tmux session (`tmux attach -t worktrees`)
- Any warnings or errors from the script

### Error handling

- If no name is provided, ask the user for one
- If the worktree already exists, inform the user
- If `pnpm install` fails, the script will exit — report the error and suggest the user check the worktree manually
