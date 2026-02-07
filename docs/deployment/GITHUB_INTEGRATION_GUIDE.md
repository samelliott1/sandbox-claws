# AI Agent GitHub Integration Guide

## Repository Information

**Repository Name:** `sandbox-claws`  
**Repository URL:** `https://github.com/YOUR_USERNAME/sandbox-claws`  
**Branch:** `main`

---

## What You Need to Provide to the AI Agent

In your new chat session with the AI agent, provide the following information:

### 1. Repository Connection Details

```
GitHub Repository: https://github.com/YOUR_USERNAME/sandbox-claws
Branch: main
Personal Access Token: [YOUR_TOKEN_HERE]
```

### 2. Initial Instructions to AI Agent

Copy and paste this to the AI agent:

```
Please connect to my GitHub repository with the following details:

Repository: https://github.com/YOUR_USERNAME/sandbox-claws
Branch: main
Token: [PASTE_YOUR_PERSONAL_ACCESS_TOKEN]

This is the Sandbox Claws project - a secure AI agent testing framework with egress control.

The repository should already have an initial commit with all project files. I need you to:
1. Verify connection to the repository
2. Confirm you can see the existing files
3. Be ready to make commits and updates as needed

The main documentation files are:
- README.md
- COMPLETE_PROJECT_SPECIFICATION.md
- SHARE_WITH_MODELS.md
- index.html
```

---

## How to Create Your Personal Access Token

### Step-by-Step Token Creation:

1. **Navigate to GitHub Token Settings:**
   - Go to: https://github.com/settings/tokens?type=beta
   - Or: GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens

2. **Click "Generate new token"**

3. **Configure Token Settings:**

   **Token name:** `sandbox-claws-ai-agent`
   
   **Expiration:** 90 days (or your preference)
   
   **Description:** `AI agent access for Sandbox Claws repository maintenance`
   
   **Repository access:** 
   - Select "Only select repositories"
   - Choose: `sandbox-claws`

4. **Set Repository Permissions:**
   
   Expand "Repository permissions" and set:
   
   - ✅ **Contents:** `Read and write`
   - ✅ **Metadata:** `Read-only` (automatically selected)
   - ✅ **Pull requests:** `Read and write` (optional, for PR creation)
   - ✅ **Issues:** `Read and write` (optional, for issue management)

5. **Generate and Copy Token:**
   - Click "Generate token" at the bottom
   - **IMMEDIATELY COPY THE TOKEN** (you won't see it again!)
   - Store it securely

---

## Verifying Your Repository is Ready

Before connecting the AI agent, verify your repository has been initialized:

```bash
# In your local project directory:

# Check git status
git status

# Verify remote is set
git remote -v
# Should show: origin  https://github.com/YOUR_USERNAME/sandbox-claws.git

# Check your branch
git branch
# Should show: * main

# Verify files are committed
git log --oneline
# Should show your initial commit
```

---

## Project Context for AI Agent

### Project Overview
Sandbox Claws is a secure AI agent testing framework with three security profiles:
- **Basic:** Container isolation with full internet access
- **Filtered:** Egress proxy with allowlist-only domains
- **Air-Gapped:** Complete network isolation with mock APIs

### Key Files Structure
```
sandbox-claws/
├── README.md                          # Main documentation
├── COMPLETE_PROJECT_SPECIFICATION.md  # Technical specification
├── SHARE_WITH_MODELS.md               # AI agent reference
├── REVISION_SUMMARY.md                # Recent changes log
├── index.html                         # Web dashboard
├── deploy.sh                          # Deployment script
├── docker-compose.yml                 # Container orchestration
├── css/                               # Stylesheets
├── js/                                # JavaScript files
├── docker/                            # Container definitions
├── security/                          # Security configurations
├── scripts/                           # Helper scripts
└── docs/                              # Additional documentation
```

### Current Status
- ✅ Complete rewrite with professional tone
- ✅ All documentation revised for security-focused audiences
- ✅ Removed hype markers and enthusiastic language
- ✅ Technical content preserved and enhanced
- ✅ Ready for public release

---

## What the AI Agent Can Do Once Connected

### Capabilities:
- ✅ Read all repository files
- ✅ Create new files
- ✅ Modify existing files
- ✅ Commit changes with descriptive messages
- ✅ Push commits to main branch
- ✅ Create branches (if needed)
- ✅ Create pull requests (if permission granted)
- ✅ Manage issues (if permission granted)

### Typical Tasks:
- Update documentation
- Fix bugs or typos
- Add new features
- Improve code quality
- Respond to issues
- Update configuration files

---

## Sample Commands for AI Agent

Once connected, you can ask the AI agent to:

```
"Read the current README.md and check for any issues"

"Update the deploy.sh script to add error handling"

"Create a new document: docs/TROUBLESHOOTING.md"

"Fix the typo in COMPLETE_PROJECT_SPECIFICATION.md line 45"

"Add a section about Kubernetes deployment to the roadmap"

"Update the version number in all relevant files to 1.0.1"

"Create a CHANGELOG.md file documenting all changes"
```

---

## Security Best Practices

### Token Security:
- ✅ Never share your token publicly
- ✅ Use fine-grained tokens (not classic tokens)
- ✅ Set expiration dates
- ✅ Limit to specific repositories
- ✅ Grant minimum required permissions
- ✅ Revoke tokens when no longer needed

### Token Storage:
- Store in password manager
- Never commit to repository
- Don't share in screenshots
- Rotate regularly

### If Token is Compromised:
1. Go to https://github.com/settings/tokens
2. Find the compromised token
3. Click "Revoke" immediately
4. Generate a new token
5. Update AI agent with new token

---

## Troubleshooting

### If AI Agent Cannot Connect:

**Check Repository Visibility:**
- Ensure repository is not deleted
- Verify URL is correct
- Confirm repository is public or token has access

**Check Token Permissions:**
- Token must have "Contents: Read and write"
- Token must not be expired
- Token must be for the correct repository

**Check Token Format:**
- Fine-grained tokens start with: `github_pat_`
- Classic tokens start with: `ghp_`
- Ensure no extra spaces when pasting

### If Commits Fail:

**Verify Branch:**
- Default branch should be `main`
- Check: Repository Settings → General → Default branch

**Check Permissions:**
- Token must have write access
- Repository must not have branch protection preventing direct commits

---

## Next Steps After Connection

1. **AI Agent verifies connection:**
   - Lists repository files
   - Confirms read/write access
   - Shows current branch

2. **Begin collaboration:**
   - Request updates or improvements
   - Ask for new features
   - Request bug fixes
   - Generate additional documentation

3. **Maintain project:**
   - Regular updates
   - Documentation improvements
   - Security patches
   - Feature additions

---

## Quick Reference

### Information to Provide AI Agent:
```
Repository: https://github.com/YOUR_USERNAME/sandbox-claws
Branch: main
Token: [YOUR_FINE_GRAINED_PERSONAL_ACCESS_TOKEN]
```

### Token Creation URL:
https://github.com/settings/tokens?type=beta

### Repository Settings URL:
https://github.com/YOUR_USERNAME/sandbox-claws/settings

### Token Permissions Required:
- Contents: Read and write
- Metadata: Read-only

---

## Support

If you encounter issues:
1. Verify token is valid and not expired
2. Check repository exists and is accessible
3. Confirm token has correct permissions
4. Try regenerating the token
5. Ensure repository URL is exactly correct

---

**You're ready to connect the AI agent to your GitHub repository!**

Just provide the repository URL and your Personal Access Token in a new chat, and the AI agent will be able to manage your Sandbox Claws project.
