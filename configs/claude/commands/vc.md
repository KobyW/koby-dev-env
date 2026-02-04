---
description: verify a claim or a set of requirements and map it to the actual code and app flow.
argument-hint: [paste claim/instructions]
---
Instructions / claim:
$ARGUMENTS

# Verify claim (VC)

## Output (use these headings)
### 1) What the claim is
- Restate the claim(s) as atomic, testable statements (bullets).
- If the text is instructions rather than a claim, extract the implied claims/requirements.

### 2) Where it appears in the app flow
For each atomic claim:
- Entry point(s): route/page/screen, user action, feature flag, CLI job, webhook, etc.
- Frontend: key components/modules involved
- Backend: endpoints/handlers/services/jobs involved
- Data: tables/collections/indexes/queues touched
- External deps: Stripe/Openrouter/etc if relevant

### 3) Evidence in the repo
For each atomic claim, provide:
- Files + symbols (function/class) that implement it
- Concrete pointers: filenames and the exact identifiers to search for
- If unsupported/contradicted, say so and show the conflicting code paths

### 4) Verification approach
Provide a minimal plan to prove/disprove:
- What to search
- What to run (tests, local repro steps, curl commands, UI steps)
- What logs/metrics would confirm it
Only propose commands; don’t execute destructive changes unless asked.

### 5) Solution approach (if the claim is false or incomplete)
- Smallest viable change path
- Risks / edge cases
- Tests to add/update
- Rollout notes (flags, migrations)

## Rules
- Prefer repo evidence over assumptions.
- If info is missing, list exactly what’s missing and proceed with best-effort verification anyway.
- Offer to implement the suggested change(s). Don't implement/change anything before asking


