# CI/CD Guide - GitHub Actions

## 📋 Overview

This project uses **GitHub Actions** to automatically run Flutter tests on every push and pull request.

## 🚀 How It Works

### Automatic Test Execution

Tests run automatically when:
- ✅ You push code to `main`, `master`, or `develop` branches
- ✅ You create or update a pull request
- ✅ You modify files in `BCSLens-frontend/` directory

### What Happens

1. **Checkout Code**: GitHub checks out your repository
2. **Setup Flutter**: Installs Flutter 3.32.5
3. **Install Dependencies**: Runs `flutter pub get`
4. **Run Tests**: Executes all 54 test cases
5. **Generate Coverage**: Creates coverage report
6. **Show Results**: Displays test results in GitHub UI

## 📊 Viewing Test Results

### On GitHub

1. **Go to Actions Tab**:
   - Click on "Actions" tab in your GitHub repository
   - You'll see a list of all workflow runs

2. **View Test Results**:
   - Click on any workflow run to see details
   - Green checkmark ✅ = All tests passed
   - Red X ❌ = Some tests failed

3. **See Test Summary**:
   - Scroll down to see test execution details
   - View coverage reports
   - See which tests passed/failed

### Status Badge

The README.md includes a status badge that shows:
- ✅ **Green**: All tests passing
- ❌ **Red**: Tests failing
- ⏳ **Yellow**: Tests running

**Note**: Update the badge URL in README.md with your actual repository path:
```markdown
[![Flutter Tests](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/flutter_tests.yml/badge.svg)]
```

Replace:
- `YOUR_USERNAME` with your GitHub username
- `YOUR_REPO` with your repository name

## 🔧 Configuration

### Workflow File Location

The CI/CD configuration is in:
```
.github/workflows/flutter_tests.yml
```

### Customization

You can modify the workflow to:
- Change Flutter version
- Add more test commands
- Upload artifacts
- Send notifications

## 📝 Test Results in Pull Requests

When you create a pull request:
- GitHub automatically runs tests
- Test results appear as **status checks**
- You can see if tests pass before merging

### Status Checks

- ✅ **All checks passed**: Ready to merge
- ❌ **Some checks failed**: Fix issues before merging
- ⏳ **Checks in progress**: Wait for completion

## 🐛 Troubleshooting

### Tests Fail on GitHub but Pass Locally

**Possible causes:**
1. Environment differences
2. Missing dependencies
3. Flutter version mismatch

**Solution:**
- Check the Actions log for error details
- Ensure `.env` file is not required (tests should work without it)
- Verify Flutter version matches workflow

### Workflow Not Running

**Check:**
1. Is the workflow file in `.github/workflows/`?
2. Are you pushing to the correct branch?
3. Did you modify files in `BCSLens-frontend/`?

### Coverage Not Showing

Coverage reports are generated but may require additional setup:
- Codecov integration (optional)
- GitHub Pages for coverage reports (optional)

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [GitHub Actions for Flutter](https://github.com/subosito/flutter-action)

## 💡 Tips

1. **Always check Actions tab** before merging PRs
2. **Fix failing tests** before pushing to main branch
3. **Use status badges** to show project health
4. **Review test logs** to understand failures

---

**Last Updated**: November 2025

