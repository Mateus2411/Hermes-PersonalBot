# Agent Orchestration Architecture

> Reference: the full delegation and orchestration system. Load this when the user asks how agent orchestration works, or when designing multi-agent workflows.

## Core Mechanism: `delegate_task`

The fundamental building block. Creates a subagent with isolated context, tools, and lifetime.

### Three Modes

| Mode | Syntax | Use Case |
|---|---|---|
| **Single** | `delegate_task(goal, context, toolsets)` | One focused task |
| **Batch (parallel)** | `delegate_task(tasks=[{goal, context}, ...])` | Up to 3 independent tasks concurrently |
| **Orchestrator** | `delegate_task(role='orchestrator', ...)` | Subagent that can spawn its own subagents |

### Agent Roles

- **Leaf agent** (default) — Gets tools, executes work, returns result. Cannot delegate further.
- **Orchestrator agent** — Gets the `delegate_task` tool. Can break its own goal into sub-tasks and delegate them. Useful for deep task graphs where the top-level agent shouldn't micro-manage every level.

### Parallel Execution Rules

- Maximum **3 concurrent subagents** (the tool enforces this).
- Each subagent gets an **independent** terminal, filesystem, and tool context — no shared state.
- Subagents cannot interfere with each other's files or processes.
- **Only dispatch in parallel when tasks are truly independent**:
  - Different files / subsystems
  - No shared mutable state
  - No sequential dependency (Task B doesn't need Task A's output)
- **Do NOT dispatch parallel implementations that edit the same file** — conflicts guaranteed.

## Orchestration Hierarchy

```
You (main session agent)
├── delegate_task() → Leaf Subagent
│   ├── Has terminal, file, web, memory tools
│   ├── Cannot delegate further
│   └── Returns result or summary
│
├── delegate_task(role='orchestrator') → Orchestrator Subagent
│   ├── Has delegate_task() tool
│   ├── Can spawn its own Leaf or Orchestrator subagents
│   └── Useful for deep decomposition
│
├── delegate_task(tasks=[...]) → Parallel Batch
│   ├── Up to 3 independent tasks
│   ├── All run concurrently
│   ├── Each has isolated context
│   └── All results returned together
│
└── Kanban Board → Multi-Profile Workflow
    ├── Each card assigned to a profile (specialist)
    ├── Dependency-engine manages ordering (parents/children)
    ├── Survives crashes and restarts
    └── Human-in-the-loop via block/unblock
```

## When to Use Each Pattern

| Pattern | When | Example |
|---|---|---|
| **Single delegate** | One clear isolated task | "Read this file and summarize it" |
| **Parallel batch** | 2-3 independent tasks, no shared state | "Fix 3 unrelated test failures" |
| **Orchestrator** | Deep decomposition, tree-shaped work | "Plan then implement a full feature" |
| **Kanban** | Multi-profile, long-running, human-review needed | "Migrate database with research + review" |
| **Subagent-Driven Dev** | Implementation with quality gates | "Implement feature with spec + code review" |

## Rule: Context Isolation

Subagents **never inherit** the parent's context, history, or conversation. You must construct exactly what they need:

```
✅ GOOD: delegate_task(
    goal="Refactor X",
    context="File structure, relevant types, constraints"
)

❌ BAD: "Refactor X" — subagent has zero context about the project
```

## Rule: Status Handling

Subagents return one of four statuses:

| Status | Action |
|---|---|
| `DONE` | Proceed |
| `DONE_WITH_CONCERNS` | Read concerns, address if needed, proceed |
| `NEEDS_CONTEXT` | Provide missing info, re-dispatch |
| `BLOCKED` | Assess: need more context? harder model? break task down? |

**Never** ignore a BLOCKED escalation or blindly retry unchanged.

## Cost Strategy (Free Models)

When using free/all-capable models (like `big-pickle`):

- You can afford to spawn parallel subagents freely — no token-cost worry
- You can run spec + quality reviewers on every task without budget concern
- The bottleneck shifts from cost to **context window**: each subagent's full task context must fit in its model's limit
