@echo off
REM Pre-push validation script for Windows
REM Run this before pushing to ensure CI will pass

echo 🔍 Running pre-push checks...
echo.

REM Check formatting
echo 📝 Checking code formatting...
dart format --output=none --set-exit-if-changed .
if errorlevel 1 (
    echo ❌ Code formatting issues found. Run: dart format .
    exit /b 1
)
echo ✅ Code formatting OK
echo.

REM Analyze code
echo 🔬 Analyzing code...
flutter analyze
if errorlevel 1 (
    echo ❌ Analysis found issues
    exit /b 1
)
echo ✅ Analysis passed
echo.

REM Run tests
echo 🧪 Running tests...
flutter test
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)
echo ✅ All tests passed
echo.

REM Generate coverage
echo 📊 Generating test coverage...
flutter test --coverage >nul 2>&1
if exist coverage\lcov.info (
    echo ✅ Coverage report generated
) else (
    echo ⚠️  Warning: Coverage report not generated
)
echo.

echo ✨ All checks passed! Safe to push.
