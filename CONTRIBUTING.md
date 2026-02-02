# Contributing to Agent Sandbox

Thank you for your interest in contributing to Agent Sandbox! This document provides guidelines for contributing to the project.

## 🎯 Project Goals

Agent Sandbox aims to provide:
1. **Security-first** testing environment for AI agents
2. **Minimal setup** with automated deployment
3. **Professional tooling** for documentation and reporting
4. **Production-ready** deployments (Docker, Proxmox, etc.)

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Test thoroughly in isolated environment
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

## 📝 Code Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Include error handling (`set -e`)
- Add comments for complex logic
- Follow [ShellCheck](https://www.shellcheck.net/) guidelines

### Docker
- Use official base images
- Run as non-root user
- Implement health checks
- Document all build args

### Documentation
- Use clear, concise language
- Include examples
- Keep security considerations visible
- Update README when adding features

### Security
- Never commit credentials
- Use environment variables for secrets
- Document security implications
- Test in isolated environment first

## 🧪 Testing

Before submitting:

1. **Test the deployment script**
   ```bash
   ./deploy.sh
   ```

2. **Verify Docker deployment**
   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs
   ```

3. **Check the web UI**
   - Open http://localhost:8080
   - Test all major features
   - Verify data persistence

4. **Security validation**
   - No exposed secrets
   - Proper isolation
   - Non-root execution

## 📋 Pull Request Process

1. Update README.md if adding features
2. Update relevant documentation
3. Ensure all tests pass
4. Request review from maintainers
5. Address feedback promptly

### PR Title Format

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `security:` - Security improvements
- `chore:` - Maintenance tasks

Examples:
- `feat: add Kubernetes deployment option`
- `fix: resolve Docker networking issue`
- `docs: update Proxmox setup guide`
- `security: harden container isolation`

## 🐛 Bug Reports

When reporting bugs, include:

1. **Environment details**
   - OS and version
   - Docker/Proxmox version
   - Deployment method

2. **Steps to reproduce**
   - Clear, numbered steps
   - Expected vs actual behavior

3. **Logs and output**
   - Error messages
   - Relevant logs
   - Screenshots if applicable

4. **Context**
   - What were you trying to accomplish?
   - Has it ever worked?

## 💡 Feature Requests

When suggesting features:

1. **Problem description**
   - What problem does this solve?
   - Who benefits from this?

2. **Proposed solution**
   - How would it work?
   - Are there alternatives?

3. **Security considerations**
   - Any security implications?
   - How to maintain isolation?

## 🔒 Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email security concerns privately
2. Provide detailed description
3. Allow time for fix before disclosure
4. Follow responsible disclosure

## 📚 Documentation Improvements

Documentation PRs are always welcome:

- Fix typos or unclear wording
- Add examples
- Improve formatting
- Translate to other languages
- Add troubleshooting guides

## 💬 Communication

- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - Questions, ideas, general chat
- **Pull Requests** - Code contributions

## ⚖️ Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment
- Follow the [Contributor Covenant](https://www.contributor-covenant.org/)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be:
- Listed in README acknowledgments
- Credited in release notes
- Appreciated for making this project better!

Thank you for contributing to Agent Sandbox! 🎉
