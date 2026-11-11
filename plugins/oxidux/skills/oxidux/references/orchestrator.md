# Orchestrator workflow

You split a job into subtasks, assign them, answer questions, review deliveries and close the parent.
You do not do the subtasks yourself unless the user asks.

## 1. Plan

1. Agree the goal and the split with the user before creating anything.
2. One `create_plan` call creates the parent and the ordered subtasks. Per subtask:
   - `prompt`: the full instructions (template below). The subagent sees nothing else.
   - `agent`: the subagent that must do it, or empty for anyone.
   - `depends_on`: numbers (1-based) of earlier subtasks that must be DONE first.
   - `requires_review: true` when the result needs your approval (UI, public text, risky changes).
3. Keep subtasks small enough for one agent session, with no two subtasks editing the same files at
   the same time unless one depends on the other.
4. Add more steps later with `create_plan` and `parent_id`; change assignment or dependencies with
   `update_task`.

### Subtask prompt template

```markdown
## Goal
<one or two sentences>

## Context
- Repo / branch: …
- Relevant files: …
- Read first: <links, attachments, earlier subtasks>

## Constraints
- <what must not change, style rules, limits>

## Done when
- [ ] <checkable item>
- [ ] <tests / lint that must pass>

## Deliver
<what to put in the summary or as evidence: commit, PR, screenshot…>
```

## 2. Launch subagents

Give each subagent its `agent` name, the workspace ID, the parent task ID, and tell it to follow the
subagent workflow. In Claude Code, the `oxidux:oxidux-worker` agent of this plugin does exactly that:
start one per agent name, e.g. "Use oxidux-worker as `ui-worker` on plan <parent_id> in workspace <id>".

## 3. Follow

- `get_activity` with `parent_id` is your inbox: new comments (look for `kind: question`), status
  changes, expired leases. Pass the returned `cursor` as `since` next time to see only what is new.
- `get_plan` gives the whole picture: each subtask's status, agent, lease, blockers, last comment and
  unanswered questions.
- Answer questions with `comment_task` `kind: "answer"` on that subtask.
- Expired lease: the task is back in TODO; check its comments and relaunch a subagent if needed.

## 4. Review

For each task in FEEDBACK: read the `handoff` comment and evidence (`list_comments`, `read_file`), check
the result yourself (diff, tests, screenshot), then `review_task`:
- `approve: true` → DONE.
- `approve: false` + `comment` saying exactly what to change (and optionally an `image` marked up) →
  back to TODO for the same agent.

## 5. Close

When every subtask is DONE, verify the overall goal, then close the parent with `update_task`
`status: "DONE"` (or `complete_task` if you claimed it) and give the user a short report: what was done,
where, and what is still pending.
