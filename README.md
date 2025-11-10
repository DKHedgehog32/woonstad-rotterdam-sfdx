# Woonstad Rotterdam - Salesforce DevOps

Salesforce metadata and CI/CD configuration for Woonstad Rotterdam using SFDX Hardis.

## 🏗️ Project Structure
```
woonstad-rotterdam-sfdx/
├── force-app/              # Salesforce metadata
├── config/                 # Scratch org definitions
├── .github/workflows/      # CI/CD pipelines
├── manifest/               # Deployment manifests
└── .sfdx-hardis.yml       # SFDX Hardis configuration
```

## 🌿 Branch Strategy

| Branch | Environment | Purpose |
|--------|-------------|---------|
| `main` | **WSRPROD** (Production) | Live production environment |
| `wsrpreprod` | **WSRPREPROD** | Pre-production validation |
| `wsruat` | **WSRUAT** | User Acceptance Testing |
| `wsrtrain` | **WSRTRAIN** | Training environment (synced from UAT) |
| `wsrtest` | **WSRTEST** | Integration/Development testing |
| `feature/*` | Scratch Orgs | Developer feature branches |

## 🚀 Getting Started

### Prerequisites

- Visual Studio Code
- Salesforce CLI
- SFDX Hardis VS Code Extension
- Git
- Access to Woonstad Rotterdam Salesforce orgs

### Installation

1. **Clone the repository:**
```bash
   git clone https://github.com/woonstadrotterdam/woonstad-rotterdam-sfdx.git
   cd woonstad-rotterdam-sfdx
```

2. **Install dependencies:**
   - Open project in VS Code
   - Click the Hardis Group icon in the left sidebar
   - Follow prompts to install required tools

3. **Authenticate to your development org:**
```bash
   sf org login web --alias wsrtest
```

## 👨‍💻 Developer Workflow

### Create a New Feature
```bash
# 1. Start from latest wsrtest
git checkout wsrtest
git pull origin wsrtest

# 2. Create feature branch
git checkout -b feature/WSR-123-description

# 3. Create scratch org
sf org create scratch -f config/project-scratch-def.json -a my-feature

# 4. Make changes in scratch org

# 5. Retrieve changes
sf project retrieve start

# 6. Commit and push
git add .
git commit -m "WSR-123: Feature description"
git push origin feature/WSR-123-description

# 7. Create Pull Request on GitHub
```

### Pull Request Process

1. Create PR from your `feature/*` branch to `wsrtest`
2. Automated checks run (deployment simulation, code quality, tests)
3. Address any issues identified by CI/CD
4. Request review from team
5. Merge after approval

## 📦 Deployment Flow
```
Scratch Org → WSRTEST → WSRUAT → WSRPREPROD → WSRPROD
                          ↓
                      WSRTRAIN (parallel)
```

**Promotion Process:**
- Each promotion requires a Pull Request
- Automated deployment checks run on every PR
- Approvals required for UAT → PREPROD → PROD
- Training environment synced from UAT (one-way)

## 🔧 Configuration

### SFDX Hardis Configuration

Main configuration is in `.sfdx-hardis.yml`:

- **Delta Deployments**: Enabled - Only deploy changed metadata
- **Smart Tests**: Enabled - Skip unnecessary Apex tests
- **Overwrite Management**: Profiles and Permission Sets protected
- **Source Cleaning**: Automatic metadata cleanup before commits

### GitHub Actions

CI/CD workflows automatically:
- ✅ Validate deployments on Pull Requests
- ✅ Run Apex tests
- ✅ Check code quality
- ✅ Deploy to target org after merge
- ✅ Post detailed results as PR comments

## 📚 Documentation

- [SFDX Hardis Documentation](https://sfdx-hardis.cloudity.com/)
- [Contributor Guide](https://sfdx-hardis.cloudity.com/salesforce-ci-cd-use-home/)
- [Release Manager Guide](https://sfdx-hardis.cloudity.com/salesforce-ci-cd-release-home/)

## 🆘 Support

### Common Issues

**Authentication expired:**
```bash
sf org login web --alias wsrtest
```

**Cannot retrieve changes:**
```bash
sf project retrieve start --source-dir force-app
```

**Merge conflicts:**
```bash
git fetch origin wsrtest
git merge origin/wsrtest
# Resolve conflicts in VS Code
git commit
```

### Contact

- **Release Managers**: [contact information]
- **DevOps Support**: [contact information]
- **Technical Issues**: Create GitHub issue

## 📜 License

[Add your license information]

## 🏢 About Woonstad Rotterdam

[Add company information]

---

**Last Updated**: January 2025
