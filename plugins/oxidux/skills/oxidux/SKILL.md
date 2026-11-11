---
name: oxidux
description: Work with Oxidux tasks through its MCP server — pick up, do, hand in, create and review tasks, alone or as an orchestrator or subagent of an agent swarm. Use when the user asks to work, create, plan, review or organize Oxidux tasks, mentions an Oxidux workspace, project or task link/ID, or asks to split a job among several agents.
---

# Oxidux tasks

Oxidux is a task board that humans and agents share. Its MCP server (`oxidux`) exposes the tools.
Reply to the user in their language; write task text in the language the workspace already uses.

## 1. Before any call

- **Workspace and project.** Look for a line `Oxidux: workspace=<uuid> project=<uuid>` in the
  project's `CLAUDE.md` or `AGENTS.md`. If there is none, call `list_workspaces` (and `list_projects`),
  ask the user which one, and offer to save that line in `CLAUDE.md`. Never guess an ID.
- **Agent name.** Use one stable name for the whole session and pass it as `agent` on every call that
  accepts it: the role you were given (`ui-worker`, `orchestrator`…) or, working alone,
  `claude-code@<hostname>`. Leases and comments are matched by this name; changing it orphans them.
- **Role.** Pick one and read its reference before acting:
  - Working tasks one by one, or a subagent told to take tasks from a plan → [references/subagent.md](references/subagent.md)
  - Asked to split a job among agents, or to supervise/review their work → [references/orchestrator.md](references/orchestrator.md)
  - Tool details, error meanings and limits → [references/tools.md](references/tools.md)

## 2. Rules that always apply

1. **Claim before working.** `claim_task` or `claim_next_task` returns a `lease_id`; without it you do not
   own the task. Never work a task another agent holds (`list_leases`, `get_task`).
2. **Read before working.** Description (it is the prompt), `list_comments`, subtasks, attachments
   (`read_file` shows images as images). If it is a subtask, read the parent too.
3. **Keep the lease alive.** Leases last 15 min by default. Call `renew_lease` every ~10 min of work, or
   claim with a longer `lease_minutes` (max 120) for long jobs.
4. **Comment only what matters,** with the right `kind`: `note` (decision, change of plan),
   `question` (you cannot continue without an answer), `answer`, `review`, `handoff`.
5. **Close properly.** `complete_task`, or `submit_for_review` if the task `requires_review`. The summary
   always says: what changed, where (commit, PR, file, URL), and what was not verified. Long reports
   go as a file (`attach_file` or the `evidence` field), not pasted into the summary.
6. **If blocked,** `release_task` with a `reason` instead of letting the lease expire silently.
7. **Respect others' work.** Do not edit, re-prioritize, change status of, or delete tasks you did not
   create in this session without asking the user. Never claim a task assigned to another agent.
8. **Ask before bulk changes.** Show the user the list before creating more than 5 tasks outside a
   plan they already approved.

## 3. Writing a task

- Title: an action ("Add retry to webhook sender"), not a topic ("Webhooks").
- Description in Markdown with: goal, context (files, links), constraints, and a **Done when** list
  of checkable items. For a subagent, the description is its whole prompt: it starts with no other
  context. See the template in [references/orchestrator.md](references/orchestrator.md).
- Priority with a reason. Big jobs become a parent task with ordered subtasks (`create_plan`).
