---
name: plan-feature
description: "TRIGGER when: the user explicitly asks for a plan — 'plan this', 'plan out X', 'make a plan for X', 'write a design for X'. SKIP when: the user asks for a feature, change, or fix without asking for a plan — 'add X', 'I want X', 'can you build X', 'how should I do X' — do the work or answer directly instead; also skip when implementing an already-approved plan. Enforces plan-before-build: design.md and tasks.md per feature, every decision naming a rejected alternative, approval before implementation."
---

## Usage

The text following `/plan-feature` is the feature to plan. Read it as a
description of what to plan, never as an instruction to build it — phrasing
like `/plan-feature add a header to this page` is still a request for a plan.
With no text following, plan the feature under discussion in the conversation;
if there is none, ask which feature to plan rather than guessing.

## Rules

- Before planning, read the existing code in the areas the feature touches, and check whether `l-stack/changes/` already has a directory for it. Extend an existing plan rather than starting a parallel one.
- Every ###  under ## Decisions names at least one rejected alternative and why it lost.
- If you reach a decision where no alternative was genuinely considered, state that explicitly in the Decisions entry rather than inventing a rejected option to fill the slot.
- ## Open Questions is either empty or every entry is marked blocking / deferrable, with the reason it's safe to defer.
- For each new proposed feature create a new directory `l-stack/changes/<feature>`.
- Each feature directory should contain a `tasks.md` file and a `design.md` file.
- `tasks.md` should contain a list of tasks that needs to be implemented.
- `design.md` contains the overall design decisions, in these sections and in this order: `## Goals / Non-Goals`, `## Decisions`, `## Risks / Trade-offs`, `## Open Questions`.
- If the feature is a single obvious change with no real design choices, say so and skip the plan directory — propose the change directly instead. The plan apparatus is for work where the alternatives matter.
- Once the plan is ready present the plan and wait for approval before implementing anything.

## Examples

**DO:**
```markdown
### Poll, rather than receive webhooks
Group webhooks don't exist on this instance, so a webhook design means one
webhook per project — per-repo setup and a hosted listener.
Rejected: a system hook. Works, but delivers every MR on the instance and
still needs membership filtering. Keep in reserve if latency matters.
```

**DON'T:**
```markdown
### Use polling
We'll poll the API every minute.
```

### tasks.md example
```
# Tasks
- [ ] 1. Add `.gitlab-ci.yml` with a single `lint` stage that runs `just lint`.
      Verify: push a branch; the pipeline appears and goes green.
- [ ] 2. Make the lint stage fail the pipeline on a bad skill.
      Verify: temporarily break a `SKILL.md` frontmatter; the job exits non-zero.
- [ ] 3. Pin the runner image to a tagged version rather than `latest`. (Decisions → "Pin the CI image")
      Verify: re-running an old pipeline produces the same result.
```

### design.md example
```
# Design

## Goals / Non-Goals
**Goals:**

- A dispatcher with no inbound network, no database, and no persistent volume,
  so the deployment target stays interchangeable.
- Correct resume after a restart with nothing persisted locally.
- Spend bounded before the first model call, not after the first invoice.

**Non-Goals:**

- Changing anything about how a review is produced or published. If this change
  edits `review/` or `publish/` beyond adding a marker, something has gone wrong.
- A UI, an API, or any way to request a review other than membership.
- Reacting within seconds. A minute of latency is fine for code review.

## Decisions

### Poll, rather than receive webhooks

Group webhooks do not exist on this instance, so a webhook design means a
webhook per project — per-repo setup *and* a hosted listener, which is strictly
worse than either alternative. A poller that was down for an hour catches up on
its next cycle.

Rejected: a system hook (instance-wide, Free, admin-only). It would work, but it
delivers every merge request on the instance and then needs membership filtering
anyway — so it buys latency at the cost of admin configuration and an ingress.
Keep it in reserve if latency ever matters.

## Risks / Trade-offs

- **The deployment target may not reach the internal model endpoint** → This
  blocks everything, so it is task 1 and nothing is built before it answers.
- **Membership enables a whole group in one action** → Concurrency cap, per-day
  ceiling, and a per-cycle cap, all checked before any model request. Pilot in
  dry run with the bot in one project.
  
## Open Questions

- Which deployment target, and whether the daily counter lives in the report
  store or somewhere the target already provides. Deferrable: the service needs
  no ingress, no volume, and no database, so the target does not constrain the
  design — every candidate can host it, and picking one later reopens none of
  the decisions above.
```

### Directory structure
```
l-stack/
  changes/
    add-cicd/
      tasks.md
      design.md
```
