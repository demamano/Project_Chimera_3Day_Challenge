# Testing Guidelines

## Test Organization

```
tests/
├── unit/                  # Unit tests
├── integration/           # Integration tests
├── e2e/                   # End-to-end tests
└── fixtures/              # Test data and mocks
```

## Test Structure

### Unit Tests

- Test individual functions/methods
- No external dependencies (mocked)
- Fast execution
- High coverage (>85%)

### Integration Tests

- Test component interactions
- Use real or in-memory databases
- Test API endpoints
- Moderate coverage (>70%)

### E2E Tests

- Test complete workflows
- Slow but comprehensive
- Focus on happy paths
- Critical scenarios only

## Test Naming Convention

```
test_<function_name>_<scenario>_<expected_result>
```

**Examples**:
- `test_authenticate_user_valid_credentials_returns_token`
- `test_get_user_by_id_user_not_found_raises_exception`
- `test_create_order_insufficient_stock_fails`

## Assertions

- One logical assertion per test (multiple physical assertions okay)
- Use specific assertion methods
- Include assertion messages
- Test both happy paths and edge cases

## Test Data

- Use fixtures for reusable test data
- Keep test data minimal and relevant
- Mock external dependencies
- Clean up after tests (teardown)

## Coverage Goals

| Category | Target |
|----------|--------|
| Unit Tests | >85% |
| Integration Tests | >70% |
| Critical Paths | 100% |
| Overall | >80% |

## Running Tests

```bash
# Run all tests
pytest tests/

# Run with coverage
pytest --cov=src tests/

# Run specific test file
pytest tests/unit/test_auth.py

# Run with verbose output
pytest -v tests/
```

---

*Last Updated: February 4, 2026*
