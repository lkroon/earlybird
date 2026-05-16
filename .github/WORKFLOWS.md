# GitHub Actions Workflows

This project uses GitHub Actions for continuous integration and deployment.

## Workflows

### 🧪 Test Workflow (`test.yml`)
**Triggers:** Push to `main`/`develop`, Pull Requests

**Steps:**
1. Checkout code
2. Setup Flutter
3. Get dependencies
4. Verify code formatting
5. Analyze code for issues
6. Run all tests
7. Generate coverage report
8. Upload coverage to Codecov (optional)

**Status:** ![Tests](https://github.com/lkroon/earlybird/workflows/Flutter%20Tests/badge.svg)

### 🏗️ Build Workflow (`build.yml`)
**Triggers:** Push to `main`, Version tags (`v*`)

**Builds:**
- **Android APK** - Release APK for Android devices
- **iOS IPA** - iOS build (no code signing)
- **Web** - Progressive web app build

**Artifacts:** Build outputs are uploaded as GitHub artifacts

**Status:** ![Build](https://github.com/lkroon/earlybird/workflows/Build%20and%20Deploy/badge.svg)

### 📊 Code Quality Workflow (`code-quality.yml`)
**Triggers:** Push to `main`/`develop`, Pull Requests

**Checks:**
1. Code formatting (dart format)
2. Static analysis (flutter analyze)
3. Outdated dependencies check
4. Test coverage generation
5. HTML coverage report

**Status:** ![Code Quality](https://github.com/lkroon/earlybird/workflows/Code%20Quality/badge.svg)

## Setup Instructions

### 1. Enable GitHub Actions
- GitHub Actions are automatically enabled for public repositories
- For private repos, go to Settings → Actions → General → Enable workflows

### 2. Add Status Badges to README
Add these badges to your main `README.md`:

```markdown
![Tests](https://github.com/lkroon/earlybird/workflows/Flutter%20Tests/badge.svg)
![Build](https://github.com/lkroon/earlybird/workflows/Build%20and%20Deploy/badge.svg)
![Code Quality](https://github.com/lkroon/earlybird/workflows/Code%20Quality/badge.svg)
```

### 3. Optional: Codecov Integration
For code coverage reports:

1. Sign up at [codecov.io](https://codecov.io)
2. Add your repository
3. Get your Codecov token
4. Add it as a GitHub secret:
   - Go to Settings → Secrets → Actions
   - Add secret: `CODECOV_TOKEN`

### 4. Optional: Slack/Discord Notifications
To get notifications when builds fail, add workflow notification steps or use GitHub's built-in notifications.

## Workflow Behavior

### On Pull Request
- ✅ Runs tests
- ✅ Checks code quality
- ✅ Analyzes code
- ❌ Does NOT build release artifacts

### On Push to Main
- ✅ Runs all tests
- ✅ Checks code quality
- ✅ Builds Android APK
- ✅ Builds iOS (no signing)
- ✅ Builds Web version

### On Version Tag (e.g., v1.0.0)
- ✅ Runs all workflows
- ✅ Creates release builds
- ✅ Uploads artifacts

## Local Testing

Test your code locally before pushing:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Generate coverage
flutter test --coverage
```

## Viewing Results

1. **GitHub Actions Tab**: See all workflow runs
2. **Pull Request Checks**: See checks at the bottom of PRs
3. **Commit Status**: See green checkmarks on commits
4. **Artifacts**: Download build artifacts from workflow runs

## Customization

### Change Flutter Version
Edit the `flutter-version` in each workflow file:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'  # Change this
    channel: 'stable'
```

### Add More Platforms
Add jobs for Windows or Linux desktop builds:

```yaml
build-windows:
  runs-on: windows-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter build windows
```

### Modify Test Coverage Threshold
Add coverage threshold checks:

```yaml
- name: Check coverage threshold
  run: |
    flutter test --coverage
    lcov --summary coverage/lcov.info
    # Add custom threshold check script
```

## Troubleshooting

### Tests Failing in CI but Not Locally
- Check Flutter version matches
- Ensure all dependencies are committed
- Check for timezone or environment differences

### Build Artifacts Not Uploading
- Verify the path in `upload-artifact` step
- Check workflow permissions in repository settings

### Workflow Not Triggering
- Verify workflow file is in `.github/workflows/`
- Check that branch names match the `on:` triggers
- Ensure workflows are enabled in repository settings

## Cost Considerations

GitHub Actions provides free minutes for public repositories and a monthly quota for private repositories:
- **Public repos**: Unlimited minutes
- **Private repos**: 2,000 minutes/month (free tier)

Each workflow run consumes minutes based on runner OS:
- Linux: 1x multiplier
- macOS: 10x multiplier
- Windows: 2x multiplier

## Best Practices

1. **Cache Dependencies**: We use `cache: true` in Flutter setup to speed up builds
2. **Fail Fast**: Tests run before builds to save time
3. **Parallel Jobs**: Build jobs run in parallel when possible
4. **Artifact Retention**: Artifacts are kept for 90 days by default
5. **Branch Protection**: Configure branch protection rules to require checks to pass

## Next Steps

1. Add more test coverage
2. Set up automatic deployment to app stores
3. Add performance benchmarks
4. Configure automated dependency updates (Dependabot)
5. Add security scanning (CodeQL)
