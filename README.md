# Project Chimera - 3 Day Challenge

A professional development project following **Spec-Driven Development** principles.

## Project Structure

```
├── specs/                 # Specification documents and requirements
├── src/                   # Source code implementation
├── tests/                 # Test suites and test utilities
├── docs/                  # Project documentation
├── config/                # Configuration files
├── README.md              # This file
└── .vscode/               # VSCode settings
```

## Development Approach

**Methodology**: Spec-Driven Development + Terence Tao's Mathematical Rigor

### Strict SDD Principles

1. **Specifications First**: All features start with detailed specs in `/specs`
2. **Clear Requirements**: Each spec defines acceptance criteria
3. **Test-Driven**: Tests are written based on specs before implementation
4. **Documentation**: Every feature is documented before coding
5. **Tracking**: All work is tracked via todo lists and analytics

### Tao's Mathematical Philosophy

- **Deep Understanding**: 40% of time on problem formulation
- **Elegant Abstraction**: Find the simplest solution that cannot be simpler
- **Rigorous Proof**: Prove correctness before implementing
- **Minimal Complexity**: Every abstraction must be mathematically justified
- **100% Correctness**: Quality and elegance over speed

**Core Principle**: "Understand deeply, formulate precisely, prove rigorously, implement elegantly."

See [TAO_PRINCIPLES.md](./docs/TAO_PRINCIPLES.md) for full framework.

## Getting Started

### Prerequisites
- VSCode with TenX Feedback Analytics configured
- Node.js or Python (depending on implementation)

### Project Setup

1. Review specifications in `./specs/`
2. Check implementation requirements in `./docs/`
3. Run tests from `./tests/`
4. Follow the todo list for development progress

## Development Workflow

1. **Specification Phase**: Define requirements in `specs/`
2. **Documentation Phase**: Document in `docs/`
3. **Test Phase**: Write tests in `tests/`
4. **Implementation Phase**: Code in `src/`
5. **Review Phase**: Validate against specs

## Tracking

Work progress is tracked using:
- **Todo Lists**: Organized task tracking
- **TenX Analytics**: Performance and competency metrics
- **Git**: Version control and change history

## Auto-Commit

This project is configured with automatic commit functionality that runs every **2 hours** to save any changes to git.

- **Status**: ✅ Active
- **Interval**: 2 hours (7200 seconds)
- **Configuration**: [Auto-Commit Guide](./docs/AUTO_COMMIT_GUIDE.md)

### Quick Commands

```bash
# Check auto-commit status
launchctl list | grep projectchimera

# Manually trigger auto-commit
bash config/auto-commit.sh

# View logs
tail -f logs/auto-commit.log

# Disable auto-commit
launchctl unload ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
```

## Quick Links

- [Tao Principles Framework](./docs/TAO_PRINCIPLES.md) - Mathematical rigor approach ⭐
- [Elon Principles Framework](./docs/ELON_PRINCIPLES.md) - Rapid iteration approach
- [Development Guidelines](./docs/DEVELOPMENT.md)
- [Specification Template](./specs/SPEC_TEMPLATE.md)
- [Test Guidelines](./docs/TESTING.md)
- [Auto-Commit Guide](./docs/AUTO_COMMIT_GUIDE.md)
- [Project Charter](./docs/PROJECT_CHARTER.md)

---

*Last Updated: February 4, 2026*
