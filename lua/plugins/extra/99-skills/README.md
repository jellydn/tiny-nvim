# 99 Custom Skills

This folder contains custom SKILL.md files for the 99 AI agent.

## How to Create Skills

1. Create a subfolder for your skill (e.g., `debug/`)
2. Add a `SKILL.md` file with your custom prompt/rules
3. Use `@skill_name` in 99 prompts to apply the skill

## Example Structure

```
99-skills/
├── README.md
├── debug/
│   └── SKILL.md
├── testing/
│   └── SKILL.md
└── refactoring/
    └── SKILL.md
```

## Example SKILL.md

```markdown
# Debug Skill

When asked to debug code:
1. Add printf/logging statements at key points
2. Focus on the current function's execution flow
3. Don't change the logic, only add observability
```
