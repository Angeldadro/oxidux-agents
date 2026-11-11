# Oxidux MCP tools

All tools take `workspace_id`. Statuses: `TODO`, `IN_PROGRESS`, `FEEDBACK` (waiting for review), `DONE`.
Priorities: `LOW` `MEDIUM` `HIGH` `URGENT` `CRITICAL`. Urgency: `LOW` `MEDIUM` `HIGH` `CRITICAL`.

## Reading

| Tool | Use |
|---|---|
| `list_workspaces`, `list_projects` | Find IDs. |
| `list_tasks` | Filter by `project_id`, `status`; `only_available` hides DONE and leased tasks. |
| `get_task` | Description, ordered subtasks, attachments, swarm info (`assigned_agent`, `requires_review`, `blocked_by`), current lease. |
| `list_comments` | Oldest first, with author, agent and kind. `since` returns only newer ones. |
| `read_file` | Opens an attachment (`attachment_id`) or a comment's file (`comment_id`). Images come back as images; text inline. |
| `list_leases` | Which tasks agents hold right now. |

## Working a task

| Tool | Use |
|---|---|
| `claim_task` | Take one task. Returns `lease_id`. |
| `claim_next_task` | Take the most important free TODO (priority, urgency, age), optionally within `project_id` or `parent_id`. Returns `null` if none. |
| `renew_lease` | Extend the lease (`lease_minutes` 1–120, default 15). |
| `extend_leases` | Before a long command: extend every lease you hold (or only `agent`'s) to `lease_minutes` from now; never shortens. |
| `release_task` | Give it back; `requeue` (default true) returns it to TODO; `reason` becomes a comment. |
| `complete_task` | DONE + `summary` as delivery comment. Not for tasks that require review. |
| `submit_for_review` | FEEDBACK + `summary` + optional `evidence` file; releases the lease. |
| `comment_task` | `content`, `kind` (`note` `question` `answer` `review` `handoff`), optional `file`. |
| `attach_file` | Attach a file to the task (base64, max 10 MB decoded). |

## Planning and supervising

| Tool | Use |
|---|---|
| `create_task` | Single task; `parent_id` for a subtask. |
| `create_plan` | Parent + ordered subtasks with `prompt`, `agent`, `requires_review`, `depends_on` (1-based numbers). |
| `update_task` | Change only the fields sent, including `assigned_agent` (`""` = anyone), `requires_review`, `depends_on` (task IDs; `[]` clears). |
| `get_plan` | Parent overview: per subtask status, agent, review, blockers, lease, last comment, open questions. |
| `get_activity` | Events since `since` (default: last hour) in the workspace or under `parent_id`; returns `cursor`. |
| `wait_for_activity` | Like `get_activity` but waits up to `timeout_seconds` (max 55) for something new; `agent` ignores your own comments; `timed_out: true` if nothing happened. |
| `review_task` | `approve: true` → DONE; `false` → TODO with `comment` and optional `image`. |
| `delete_task` | Moves to the workspace trash (restorable). Ask the user first. |

## Files

`file`, `evidence` and `image` objects are `{ file_name, mime_type, content_base64 }`, max 10 MB
decoded, and count toward the workspace's storage plan. Prefer PNG screenshots and Markdown reports.

## Errors and what to do

| Symptom | Meaning | Action |
|---|---|---|
| `renew_lease` / `complete_task` fails with lease error | Lease expired or not yours. | `get_task`: if free, claim again; if held by another agent, stop. |
| `claim_task` fails: held / assigned / blocked | Someone else has it, it is for another agent, or dependencies are unfinished. | Choose another task; never force it. |
| `claim_next_task` returns `null` | Nothing available for you. | Report and stop, or wait for dependencies. |
| HTTP 401 | Token missing, wrong or revoked. | Ask the user to check `OXIDUX_TOKEN` / create a new token in Oxidux → Settings → AI agents. |
| HTTP 403 from the server edge (not JSON) | The edge filter blocked the client. | Use the MCP tools, not raw HTTP; if scripting, send a normal `User-Agent`. |
| Storage quota error on files | The workspace plan is full. | Tell the user; link files instead of uploading. |
| Invalid arguments | Wrong IDs, enum or schema. | Re-read the IDs with `get_task` / `list_*`; do not invent them. |
