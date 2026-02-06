# Project Chimera - Skills Directory

## Overview

Skills are modular capability packages that agents can use during runtime. Each skill has a well-defined interface (input/output contracts) and uses MCP servers for external interactions.

## Available Skills

1. **skill_content_generation** - Generate multimodal social media content
2. **skill_social_publishing** - Publish content to social platforms
3. **skill_trend_analysis** - Discover and analyze trending topics

## Skill Structure

```
skills/
├── skill_name/
│   ├── README.md          # Interface definition & usage
│   ├── __init__.py        # Package initialization
│   ├── skill.py           # Core implementation
│   ├── models.py          # Pydantic schemas
│   └── tests/             # Unit tests
```

## Adding New Skills

1. Create directory: `mkdir skills/skill_new_capability`
2. Define interface in `README.md`
3. Implement `execute(input, mcp_client) -> output`
4. Write tests in `tests/`
5. Register in `services/shared/skill_registry.py`
