# Development Guidelines

## Code Standards

### File Organization

- Use meaningful, descriptive file names
- Group related functionality together
- Keep files focused and single-purpose
- Maximum 500 lines per file (consider splitting larger files)

### Naming Conventions

- **Files**: kebab-case.ext (e.g., user-service.py)
- **Functions**: snake_case (e.g., get_user_data)
- **Classes**: PascalCase (e.g., UserService)
- **Constants**: UPPER_SNAKE_CASE (e.g., MAX_RETRIES)

### Code Quality

- All code must have clear docstrings/comments
- Functions should do one thing well
- Aim for high code coverage (>80%)
- Follow DRY (Don't Repeat Yourself) principle

## Git Workflow

### Commit Messages

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Example**: `feat(auth): add OAuth2 integration`

### Branch Naming

- `feature/short-description`
- `bugfix/short-description`
- `docs/short-description`
- `chore/short-description`

## Code Review

1. All changes require peer review
2. Must pass automated tests
3. Must be spec-compliant
4. Update documentation if needed

## Performance Considerations

- Profile before optimizing
- Document performance-critical sections
- Include benchmarks in tests
- Monitor resource usage

## Security

- Never commit secrets or credentials
- Validate all inputs
- Use environment variables for config
- Regular dependency audits

---

*Last Updated: February 4, 2026*
