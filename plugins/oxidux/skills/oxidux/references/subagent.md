# Subagent (or single agent) workflow

You take tasks, do them, and hand them in with evidence. Your prompt is the task description.

## Loop

1. **Take a task.**
   - From a plan: `claim_next_task` with `parent_id` (the parent task) and your `agent` name. It skips
     tasks assigned to other agents, tasks blocked by unfinished dependencies, and parent tasks.
   - A specific task: `claim_task`. It fails if someone else holds it, it is assigned to another agent,
     or it is blocked.
   - `null` means nothing is available for you now. If `get_plan` shows tasks for you that are only
     blocked by unfinished dependencies, call `wait_for_activity` on the parent and try again when
     something changes; otherwise stop and report. Never claim tasks of others.
2. **Read everything** before touching code: `get_task` (description, subtasks, attachments,
   `blocked_by`), `list_comments` (instructions and previous reviews — if the task came back from
   review, the latest `review` comment says what to change), `read_file` for each relevant attachment.
3. **Work.** `renew_lease` every ~10 min. Before a command that may take long (build, full test suite,
   deploy), call `extend_leases` with `lease_minutes` = expected duration + 5 (the Claude Code plugin
   does this automatically for long or background Bash commands). Record decisions as `note` comments only when someone else
   would need them.
4. **Doubts.** If you cannot continue without an answer, `comment_task` with `kind: "question"`, then
   keep working on whatever does not depend on it. When you need the answer, call `wait_for_activity`
   with `parent_id` = your task ID and your `agent` (so your own comments do not wake you); repeat with
   the returned `cursor` until the `answer` arrives. Renew the lease while you wait. If you must stop,
   `release_task` with `requeue: true` and a `reason`.
5. **Hand in.**
   - `requires_review: true` → `submit_for_review` with `summary` and, when useful, `evidence`
     (a screenshot of the UI, a test log). The task goes to FEEDBACK and your lease is released.
   - Otherwise → `complete_task` with `summary`.
   - Summary format:
     ```
     Changed: <what>
     Where: <commit / PR / files / URL>
     Not verified: <what you could not check, or "nothing">
     ```
6. **Next.** Repeat from step 1 until `claim_next_task` returns `null`.

## Do not

- Work without a lease, or keep working after `renew_lease` fails (the lease expired: claim again;
  if someone else took it, stop).
- Change the description, priority or assignment of the task you are working; ask with a comment.
- Mark DONE a task that requires review.
