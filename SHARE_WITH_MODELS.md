# Sandbox Claws — Reference Document

## Purpose

This document provides context for AI models reviewing or extending this project.

## Primary Reference

All architectural decisions, implementation details, and design rationale are documented in:

**`COMPLETE_PROJECT_SPECIFICATION.md`**

## Key Concepts

1. **Three Security Profiles** — Basic, Filtered, Air-Gapped (increasing isolation)
2. **Egress Control** — Network traffic filtered through proxy with allowlist
3. **DLP Scanning** — Automated detection of sensitive data patterns in logs
4. **One-Command Deployment** — `./deploy.sh` handles all setup

## Implementation Notes

- Docker Compose orchestrates all services
- Squid proxy handles egress filtering in Filtered mode
- Network namespace isolation enforces Air-Gapped mode
- Web UI is static HTML/CSS/JS served via nginx

## Extension Points

- Add domains to `security/allowlist.txt` for Filtered mode
- Add test cases to `docs/TESTING_GUIDE.md`
- Add DLP patterns to scanner configuration
