# oxidux-agents

Claude Code plugin for [Oxidux](https://oxidux.com): let agents take, do, hand in and review Oxidux tasks —
alone, or as a swarm of one orchestrator and several subagents.

## What you get

| Piece | What it does |
|---|---|
| MCP server `oxidux` | The Oxidux tools: tasks, leases, comments, files, plans, reviews, activity. |
| Skill `oxidux` | The workflow: claim before working, keep the lease, ask through comments, hand in with evidence; plus the orchestrator and subagent playbooks. |
| Agent `oxidux-worker` | A swarm subagent: give it an agent name, a workspace and a plan; it works every task assigned to it until none is left. |

## Install

1. In Oxidux, open **Settings → AI agents** and create a token.
2. Make it available to Claude Code as `OXIDUX_TOKEN` (e.g. in your shell profile):
   ```bash
   export OXIDUX_TOKEN="<your token>"
   ```
3. In Claude Code:
   ```
   /plugin marketplace add Angeldadro/oxidux-agents
   /plugin install oxidux@oxidux-agents
   ```
4. Check with `/mcp` that `oxidux` is connected.

Optional: tell agents which workspace and project to use by adding this line to your project's
`CLAUDE.md` or `AGENTS.md`:

```
Oxidux: workspace=<workspace-uuid> project=<project-uuid>
```

Self-hosted Oxidux? Set `OXIDUX_MCP_URL` to your server's `/mcp` endpoint.

## Use it

- **Single agent:** "Take the next Oxidux task and do it."
- **Orchestrator:** "Split this job into an Oxidux plan for `ui-worker` and `api-worker`, with review on the UI parts."
  The orchestrator creates the plan; each subtask's description is the subagent's prompt.
- **Subagents:** "Use oxidux-worker as `ui-worker` on plan `<parent-id>` in workspace `<workspace-id>`."
  Run several in parallel, one per agent name.
- **Supervise:** "Check the plan's activity, answer questions and review what is in feedback."

Humans see everything in Oxidux: prompts in the task description, agent comments with their name and kind,
screenshots, and tasks waiting for review.

## Other MCP clients

The server works with any MCP client (Claude Desktop, Cursor…): add `https://api.oxidux.com/mcp` with the header
`Authorization: Bearer <token>`. The essential rules travel in the server's own instructions; the skill files in
`plugins/oxidux/skills/oxidux/` can be copied as a system prompt or rules file.

## License

MIT
